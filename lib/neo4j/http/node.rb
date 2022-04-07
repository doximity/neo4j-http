# frozen_string_literal: true

module Neo4j
  module Http
    class Node < ObjectWrapper
      DEFAULT_PRIMARY_KEY_NAME = "uuid"
      def initialize(label:, graph_node_primary_key_name: DEFAULT_PRIMARY_KEY_NAME, **attributes)
        super
      end
    end
  end
end
