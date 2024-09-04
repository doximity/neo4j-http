# frozen_string_literal: true

module Neo4j
  module Http
    class RelationshipClient
      def self.default
        @default ||= new(CypherClient.default)
      end

      def initialize(cypher_client)
        @cypher_client = cypher_client
      end

      def upsert_relationship(relationship:, from:, to:, create_nodes: false)
        if create_nodes
          NodeClient.new(@cypher_client).upsert_node(from)
          NodeClient.new(@cypher_client).upsert_node(to)
        end

        from_selector = build_match_selector(:from, from)
        to_selector = build_match_selector(:to, to)
        relationship_selector = build_relationship_match_selector(relationship)

        # cypher = +<<-CYPHER
        #   MATCH (#{from_selector})-[#{relationship_selector}]-(#{to_selector})
        #   RETURN from, to, relationship
        # CYPHER

        # results = @cypher_client.execute_cypher(
        #   cypher,
        #   from: from,
        #   to: to,
        #   relationship: relationship,
        #   relationship_attributes: relationship.attributes
        # )

        # This is necessary because AGE ignores MERGE + SET on relationship attributes
        # Because of this we cannot both MATCH on properties then SET different properties
        # The relationship has to be deleted, then subsequently recreated
        if relationship.attributes.present?
          delete_relationship(relationship:, from:, to:)
          attributes = relationship.attributes.reduce([]) {|sum, (k,v)| sum << "#{k}: '#{v}'"}.join(", ")
          cypher = <<-CYPHER
            MATCH (#{from_selector}), (#{to_selector})
            MERGE (from)-[relationship:#{relationship.label} { #{attributes} }]-(to)
            RETURN from, to, relationship
          CYPHER

          results = @cypher_client.execute_cypher(
            cypher,
            from: from,
            to: to,
            relationship: relationship,
            relationship_attributes: relationship.attributes
          )
        end
        results&.first
      end

      def find_relationships(from:, relationship:, to:)
        from_match_clause = build_match_selector(:from, from)
        to_match_clause = build_match_selector(:to, to)
        relationship_clause = build_match_selector(:relationship, relationship)
        cypher = <<-CYPHER
          MATCH (#{from_match_clause}) - [#{relationship_clause}] - (#{to_match_clause})
          RETURN from, to, relationship
        CYPHER

        @cypher_client.execute_cypher(
          cypher,
          from: from,
          to: to,
          relationship: relationship,
          access_mode: "READ"
        )
      end

      def find_relationship(from:, relationship:, to:)
        results = find_relationships(from: from, to: to, relationship: relationship)
        results&.first
      end

      def build_match_selector(name, data)
        selector = +"#{name}:#{data.label}"
        selector << " {#{data.key_name}: $#{name}.#{data.key_name}}" if data.key_name.present?
        selector
      end

      def build_relationship_match_selector(data)
        if data.key_value.present?
          "relationship:#{data.label} { #{data.key_name}: '#{data.key_value}' }"
        else
          "relationship:#{data.label} { uuid: '#{data.uuid}' }"
        end
      end

      def delete_relationship(relationship:, from:, to:)
        from_selector = build_match_selector(:from, from)
        to_selector = build_match_selector(:to, to)
        relationship_selector = build_relationship_match_selector(relationship)

        cypher = <<-CYPHER
          MATCH (#{from_selector}) - [#{relationship_selector}] - (#{to_selector})
          WITH from, to, relationship
          DELETE relationship
          RETURN from, to
        CYPHER

        results = @cypher_client.execute_cypher(cypher, from: from, to: to)
        results&.first
      end

      def delete_relationship_on_primary_key(relationship:)
        # protection against mass deletion of relationships
        return if relationship.key_name.nil?

        relationship_selector = build_match_selector(:relationship, relationship)

        cypher = <<-CYPHER
          MATCH () - [#{relationship_selector}] - ()
          WITH relationship
          DELETE relationship
          RETURN relationship
        CYPHER

        results = @cypher_client.execute_cypher(cypher, relationship: relationship)
        results&.first
      end
    end
  end
end
