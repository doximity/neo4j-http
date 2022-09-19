# frozen_string_literal: true

module Neo4j
  module Http
    class BatchRelationshipClient < RelationshipClient
      def upsert_relationship(relationship:, from:, to:, create_nodes: false)
        {
          statement: upsert_relationship_cypher(relationship: relationship, from: from, to: to, create_nodes: create_nodes),
          parameters: {
            from: from,
            to: to,
            relationship: relationship,
            relationship_attributes: relationship.attributes
          }
        }
      end

      def delete_relationship(relationship:, from:, to:)
        {
          statement: delete_relationship_cypher(relationship: relationship, from: from, to: to),
          parameters: {
            from: from,
            to: to
          }
        }
      end

      def delete_relationship_on_primary_key(relationship:)
        # protection against mass deletion of relationships
        return if relationship.key_name.nil?

        {
          statement: delete_relationship_on_primary_key_cypher(relationship: relationship),
          parameters: {
            relationship: relationship
          }
        }
      end
    end
  end
end
