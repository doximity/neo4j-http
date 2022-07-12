# frozen_string_literal: true

module Neo4j
  module Http
    class Node < ObjectWrapper
      DEFAULT_PRIMARY_KEY_NAME = "uuid"
      def initialize(label:, primary_key_name: DEFAULT_PRIMARY_KEY_NAME, **attributes)
        super
        @key_value = @attributes.delete(key_name)
      end
    end
  end
end
