# frozen_string_literal: true

module Neo4j
  module Http
    class NodeClient
      def self.default
        @default ||= new(CypherClient.default)
      end

      def initialize(cypher_client)
        @cypher_client = cypher_client
      end

      def upsert_node(node)
        raise "#{node.key_name} value cannot be blank - (node keys: #{node.to_h.keys})" if node.key_value.blank?

        cypher = <<-CYPHER
          MERGE (node:#{node.label} {#{node.key_name}: $key_value})
          ON CREATE SET node += $attributes
          ON MATCH SET node += $attributes
          return node
        CYPHER

        results = @cypher_client.execute_cypher(cypher, key_value: node.key_value, attributes: node.attributes)

        results.first&.fetch("node")
      end

      def delete_node(node)
        cypher = <<-CYPHER
          MATCH (node:#{node.label} {#{node.key_name}: $key_value})
          WITH node
          DETACH DELETE node
          RETURN node
        CYPHER

        results = @cypher_client.execute_cypher(cypher, key_value: node.key_value)
        results.first&.fetch("node")
      end

      def find_node_by(label:, **attributes)
        selectors = attributes.map { |key, value| "#{key}: $attributes.#{key}" }.join(", ")
        cypher = "MATCH (node:#{label} { #{selectors} }) RETURN node LIMIT 1"
        results = @cypher_client.execute_cypher(cypher, attributes: attributes.merge(access_mode: "READ"))
        return if results.empty?

        results.first&.fetch("node")
      end

      def find_nodes_by(label:, attributes:, limit: 100)
        selectors = build_selectors(attributes)
        cypher = "MATCH (node:#{label}) where #{selectors} RETURN node LIMIT #{limit}"
        results = @cypher_client.execute_cypher(cypher, attributes: attributes.merge(access_mode: "READ"))
        results.map { |result| result["node"] }
      end

      protected

      def build_selectors(attributes, node_name: :node)
        attributes.map do |key, value|
          if value.is_a?(Array)
            "#{node_name}.#{key} IN $attributes.#{key}"
          else
            "#{node_name}.#{key} = $attributes.#{key}"
          end
        end.join(" AND ")
      end
    end
  end
end
