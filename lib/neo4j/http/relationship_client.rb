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
        match_or_merge = create_nodes ? "MERGE" : "MATCH"
        from_selector = build_match_selector(:from, from)
        to_selector = build_match_selector(:to, to)
        relationship_selector = build_match_selector(:relationship, relationship)

        on_match = ""
        if relationship.attributes.present?
          on_match = <<-CYPHER
            ON CREATE SET relationship += $relationship_attributes
            ON MATCH SET relationship += $relationship_attributes
          CYPHER
        end

        cypher = +<<-CYPHER
          #{match_or_merge} (#{from_selector})
          #{match_or_merge} (#{to_selector})
          MERGE (from) - [#{relationship_selector}] - (to)
          #{on_match}
          RETURN from, to, relationship
        CYPHER

        results = @cypher_client.execute_cypher(
          cypher,
          from: from,
          to: to,
          relationship: relationship,
          relationship_attributes: relationship.attributes
        )
        results&.first
      end

      def find_relationship(from:, relationship:, to:)
        from_match_clause = build_match_selector(:from, from)
        to_match_clause = build_match_selector(:to, to)
        relationship_clause = build_match_selector(:relationship, relationship)
        cypher = <<-CYPHER
          MATCH (#{from_match_clause}) - [#{relationship_clause}] - (#{to_match_clause})
          RETURN from, to, relationship
        CYPHER

        results = @cypher_client.execute_cypher(cypher, from: from, to: to, relationship: relationship)
        results&.first
      end

      def build_match_selector(name, data)
        selector = +"#{name}:#{data.label}"
        selector << " {#{data.key_name}: $#{name}.#{data.key_name}}" if data.key_name.present?
        selector
      end

      def delete_relationship(relationship:, from:, to:)
        from_selector = build_match_selector(:from, from)
        to_selector = build_match_selector(:to, to)
        relationship_selector = build_match_selector(:relationship, relationship)
        cypher = <<-CYPHER
          MATCH (#{from_selector}) - [#{relationship_selector}] - (#{to_selector})
          WITH from, to, relationship
          DELETE relationship
          RETURN from, to
        CYPHER

        results = @cypher_client.execute_cypher(cypher, from: from, to: to)
        results&.first
      end
    end
  end
end
