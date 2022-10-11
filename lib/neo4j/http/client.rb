# frozen_string_literal: true

module Neo4j
  module Http
    class Client
      CYPHER_CLIENT_METHODS = %i[execute_cypher].freeze
      NODE_CLIENT_METHODS = %i[delete_node find_node_by find_nodes_by upsert_node].freeze
      RELATIONSHIP_CLIENT_METHODS = %i[delete_relationship upsert_relationship
        delete_relationship_on_primary_key].freeze
      CLIENT_METHODS = (CYPHER_CLIENT_METHODS + NODE_CLIENT_METHODS + RELATIONSHIP_CLIENT_METHODS).freeze

      class << self
        delegate(*CLIENT_METHODS, to: :default)

        def default
          cypher_client = Http::CypherClient.new(Neo4j::Http.config)
          node_client = Http::NodeClient.new(cypher_client)
          relationship_client = Http::RelationshipClient.new(cypher_client)
          @default ||= new(cypher_client, node_client, relationship_client)
        end
      end

      attr_accessor :cypher_client, :node_client, :relationship_client

      def initialize(cypher_client, node_client, relationship_client)
        @cypher_client = cypher_client
        @node_client = node_client
        @relationship_client = relationship_client
      end

      delegate(*CYPHER_CLIENT_METHODS, to: :cypher_client)
      delegate(*NODE_CLIENT_METHODS, to: :node_client)
      delegate(*RELATIONSHIP_CLIENT_METHODS, to: :relationship_client)
    end
  end
end
