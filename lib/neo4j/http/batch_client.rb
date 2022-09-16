# frozen_string_literal: true

module Neo4j
  module Http
    class BatchClient < Client
      class << self
        def default
          cypher_client = Http::BatchCypherClient.new(Neo4j::Http.config)
          node_client = Http::BatchNodeClient.new(cypher_client)
          relationship_client = Http::BatchRelationshipClient.new(cypher_client)
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
