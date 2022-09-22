# frozen_string_literal: true

module Neo4j
  module Http
    class BatchNodeClient < NodeClient
      protected

      def process_upsert_node(cypher:, node:)
        {
          statement: cypher,
          parameters: {key_value: node.key_value, attributes: node.attributes}
        }
      end

      def process_delete_node(cypher:, node:)
        {
          statement: cypher,
          parameters: {key_value: node.key_value}
        }
      end
    end
  end
end
