# frozen_string_literal: true

module Neo4j
  module Http
    class ObjectWrapper
      attr_reader :attributes,
                  :key_name,
                  :key_value,
                  :label,
                  :original_attributes

      def initialize(label:, graph_node_primary_key_name: nil, **attributes)
        @original_attributes = (attributes || {}).with_indifferent_access
        @attributes = original_attributes.dup.with_indifferent_access
        @key_name = graph_node_primary_key_name
        @key_value = @attributes.delete(key_name)
        @label = label
      end

      delegate :[], :to_h, :as_json, :to_json, to: :@original_attributes

      def method_missing(method_name, *args, &block)
        if @original_attributes.has_key?(method_name)
          original_attributes[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @original_attributes.has_key?(method_name) || super
      end
    end
  end
end
