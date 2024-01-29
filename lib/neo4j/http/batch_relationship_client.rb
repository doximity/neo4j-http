# frozen_string_literal: true

module Neo4j
  module Http
    class BatchRelationshipClient < RelationshipClient
      protected

      def process_upsert_relationship(cypher:, from:, to:, relationship:)
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

      def process_delete_relationship(cypher:, from:, to:)
        {
          statement: cypher,
          parameters: {
            from: from,
            to: to
          }
        }
      end

      def process_delete_relationship_on_primary_key(cypher:, relationship:)
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
