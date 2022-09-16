# frozen_string_literal: true

module Neo4j
  module Http
    class BatchNodeClient < NodeClient
      def upsert_node(node)
        raise "#{node.key_name} value cannot be blank - (node keys: #{node.to_h.keys})" if node.key_value.blank?

        cypher = <<-CYPHER
          MERGE (node:#{node.label} {#{node.key_name}: $key_value})
          ON CREATE SET node += $attributes
          ON MATCH SET node += $attributes
          return node
        CYPHER

        {
          statement: cypher,
          parameters: { key_value: node.key_value, attributes: node.attributes }
        }
      end

      def delete_node(node)
        cypher = <<-CYPHER
          MATCH (node:#{node.label} {#{node.key_name}: $key_value})
          WITH node
          DETACH DELETE node
          RETURN node
        CYPHER

        {
          statement: cypher,
          parameters: { key_value: node.key_value }
        }
      end
    end
  end
end
