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

      def initialize(configuration)
        @configuration = configuration
      end

      def execute_cypher(cypher, parameters = {})
        request_body = {
          statements: [
            {statement: cypher,
             parameters: parameters.as_json}
          ]
        }

        response = connection.post(transaction_path, request_body)
        results = check_errors!(cypher, response, parameters)

        Neo4j::Http::Results.parse(results&.first || {})
      end

      def connection
        build_connection
      end

      protected

      delegate :auth_token, :transaction_path, to: :@configuration
      def check_errors!(cypher, response, parameters)
        raise Neo4j::Http::Errors::InvalidConnectionUrl, response.status if response.status == 404
        body = response.body || {}
        errors = body.fetch("errors", [])
        return body.fetch("results", {}) unless errors.present?

        error = errors.first
        raise_error(error, cypher, parameters)
      end

      def raise_error(error, cypher, parameters = {})
        code = error["code"]
        message = error["message"]
        klass = find_error_class(code)
        parameters = JSON.pretty_generate(parameters.as_json)
        raise klass, "#{code} - #{message}\n cypher: #{cypher} \n parameters given: \n#{parameters}"
      end

      def find_error_class(code)
        Neo4j::Http::Errors.const_get(code.gsub(".", "::"))
      rescue
        Neo4j::Http::Errors::Neo4jCodedError
      end

      def build_connection
        Faraday.new(url: @configuration.uri, headers: build_http_headers, request: build_request_options) do |f|
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
