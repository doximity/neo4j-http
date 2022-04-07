# frozen_string_literal: true

module Neo4j
  module Http
    class Configuration
      attr_accessor :database_name
      attr_accessor :password
      attr_accessor :request_timeout_in_seconds
      attr_accessor :uri
      attr_accessor :user
      attr_accessor :user_agent

      def initialize(options = ENV)
        @uri = options.fetch("NEO4J_URL", "http://localhost:7474")
        @user = options.fetch("NEO4J_USER", "")
        @password = options.fetch("NEO4J_PASSWORD", "")
        @database_name = options.fetch("NEO4J_DATABASE", nil)
        @user_agent = options.fetch("NEO4J_HTTP_USER_AGENT", "Ruby Neo4j Http Client")
        @request_timeout_in_seconds = options.fetch("NEO4J_REQUEST_TIMEOUT_IN_SECONDS", nil)
      end

      def transaction_path
        # v3.5 - /db/data/transaction/commit
        # v4.x - /db/#{database_name}/tx/commit
        if database_name
          "/db/#{database_name}/tx/commit"
        else
          "/db/data/transaction/commit"
        end
      end

      def auth_token
        Neo4j::Http::AuthToken.token(user, password)
      end
    end
  end
end
