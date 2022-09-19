# frozen_string_literal: true

module Neo4j
  module Http
    class BatchNodeClient < NodeClient
      def upsert_node(node)
        raise "#{node.key_name} value cannot be blank - (node keys: #{node.to_h.keys})" if node.key_value.blank?

        {
          statement: upsert_node_cypher(node: node),
          parameters: { key_value: node.key_value, attributes: node.attributes }
        }
      end

      def delete_node(node)
        {
          statement: delete_node_cypher(node: node),
          parameters: { key_value: node.key_value }
        }
      end
    end
  end
end
