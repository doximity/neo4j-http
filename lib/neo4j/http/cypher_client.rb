# frozen_string_literal: true

require "forwardable"
require "faraday"
require "faraday/retry"
require "faraday_middleware"

module Neo4j
  module Http
    class CypherClient
      def self.default
        @default ||= new(Neo4j::Http.config)
      end

      def initialize(configuration, injected_connection = nil)
        @configuration = configuration
        @injected_connection = injected_connection
      end

      # Executes a cypher query, passing in the cypher statement, with parameters as an optional hash
      # e.g. Neo4j::Http::Cypherclient.execute_cypher("MATCH (n { foo: $foo }) LIMIT 1 RETURN n", { foo: "bar" })
      def execute_cypher(cypher, parameters = {})
        # By default the access mode is set to "WRITE", but can be set to "READ"
        # for improved routing performance on read only queries
        access_mode = parameters.delete(:access_mode) || @configuration.access_mode

        # https://docs.aws.amazon.com/neptune/latest/userguide/opencypher-parameterized-queries.html
        request_body = {
          query: cypher,
          parameters: parameters.as_json
        }

        @connection = @injected_connection || connection(access_mode)
        response = @connection.post(transaction_path, request_body)
        results = check_errors!(cypher, response, parameters)

        Neo4j::Http::Results.parse(results || [])
      end

      def connection(access_mode)
        build_connection(access_mode)
      end

      protected

      delegate :auth_token, :transaction_path, to: :@configuration
      def check_errors!(cypher, response, parameters)
        raise Neo4j::Http::Errors::InvalidConnectionUrl, response.status if response.status == 404
        # Neptune error format:
        # {"requestId":"c1470a57-7bd0-4b88-b86b-71e64e7e6a2d","code":"MalformedQueryException",
        # "detailedMessage":"It is not allowed to refer to variables in LIMIT (line 1, column 54 (offset: 53))",
        # "message":"It is not allowed to refer to variables in LIMIT (line 1, column 54 (offset: 53))"}

        body = response.body || {}
        errors = body.fetch("message", [])
        return body.fetch("results", {}) unless errors.present?

        error = errors.first
        raise_error(error, cypher, parameters)
      end

      def raise_error(error, cypher, parameters = {})
        parameters = JSON.pretty_generate(parameters.as_json)
        raise Neo4j::Http::Errors::Neo4jCodedError, "#{error}\n cypher: #{cypher} \n parameters given: \n#{parameters}"
      end

      def find_error_class(code)
        Neo4j::Http::Errors.const_get(code.gsub(".", "::"))
      rescue
        Neo4j::Http::Errors::Neo4jCodedError
      end

      def build_connection(access_mode)
        # https://neo4j.com/docs/http-api/current/actions/transaction-configuration/
        headers = build_http_headers.merge({"access-mode" => access_mode})
        Faraday.new(url: @configuration.uri, headers: headers, request: build_request_options) do |f|
          f.request :json # encode req bodies as JSON
          f.request :retry # retry transient failures
          f.response :json # decode response bodies as JSON
        end
      end

      def build_request_options
        request_options = {}

        timeout = @configuration.request_timeout_in_seconds.to_i
        request_options[:timeout] = timeout if timeout.positive?

        request_options
      end

      def build_http_headers
        {
          "User-Agent" => @configuration.user_agent,
          "Accept" => "application/json"
        }.merge(authentication_headers)
      end

      def authentication_headers
        return {} if auth_token.blank?

        {"Authentication" => "Basic #{auth_token}"}
      end
    end
  end
end
