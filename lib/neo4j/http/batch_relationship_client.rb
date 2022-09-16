# frozen_string_literal: true

module Neo4j
  module Http
    class BatchRelationshipClient < RelationshipClient
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

        {
          statement: cypher,
          parameters: {
            from: from,
            to: to,
            relationship: relationship,
            relationship_attributes: relationship.attributes
          }
        }
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

        {
          statement: cypher,
          parameters: {
            from: from,
            to: to
          }
        }
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

        {
          statement: cypher,
          parameters: {
            relationship: relationship
          }
        }
      end
    end
  end
end
