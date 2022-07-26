# frozen_string_literal: true

module Neo4j
  module Http
    class Relationship < ObjectWrapper
      def initialize(label:, primary_key_name: nil, **attributes)
        super
        @key_value = @attributes.dig(key_name)
      end
    end
  end
end
