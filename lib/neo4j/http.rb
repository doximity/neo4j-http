require "neo4j/http/version"

require "active_support"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/json"
require "active_support/core_ext/hash/indifferent_access"

require "neo4j/http/auth_token"
require "neo4j/http/client"
require "neo4j/http/configuration"
require "neo4j/http/cypher_client"
require "neo4j/http/object_wrapper"
require "neo4j/http/node"
require "neo4j/http/node_client"
require "neo4j/http/relationship"
require "neo4j/http/relationship_client"
require "neo4j/http/results"

require "neo4j/http/errors"

module Neo4j
  module Http
    extend self

    def config
      @congiguration ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end
