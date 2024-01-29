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

        process_upsert_relationship(cypher: cypher, from: from, to: to, relationship: relationship)
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

        process_delete_relationship(cypher: cypher, from: from, to: to)
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

        process_delete_relationship_on_primary_key(cypher: cypher, relationship: relationship)
      end

      protected

      def process_upsert_relationship(cypher:, from:, to:, relationship:)
        results = @cypher_client.execute_cypher(
          cypher,
          from: from,
          to: to,
          relationship: relationship,
          relationship_attributes: relationship.attributes
        )
        results&.first
      end

      def process_delete_relationship(cypher:, from:, to:)
        results = @cypher_client.execute_cypher(cypher, from: from, to: to)
        results&.first
      end

      def process_delete_relationship_on_primary_key(cypher:, relationship:)
        results = @cypher_client.execute_cypher(cypher, relationship: relationship)
        results&.first
      end
    end
  end
end
