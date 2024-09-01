# frozen_string_literal: true

require "forwardable"
require "faraday"
require "faraday/retry"
require "faraday_middleware"
require "pg"

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
      # e.g. Neo4j::Http::Cypherclient.execute_cypher("MATCH (n { foo: $foo }) LIMIT 1 RETURN n", ["n"], { foo: "bar" })
      def execute_cypher(cypher, parameters = {})
        # By default the access mode is set to "WRITE", but can be set to "READ"
        # for improved routing performance on read only queries
        access_mode = parameters.delete(:access_mode) || @configuration.access_mode

        @connection = @injected_connection || connection(access_mode)

        cypher = expand_parameters_for_set(cypher, parameters)

        prepared_statement = <<~SQL
          LOAD 'age';
          SET search_path = ag_catalog, "$user", public;

          PREPARE cypher_stored_procedure(agtype) AS
          SELECT *
          FROM cypher('#{@configuration.database_name}', $$
            #{ cypher }
          $$, $1)
          AS (#{return_syntax(cypher, [])});

          EXECUTE cypher_stored_procedure('#{parameters.to_json}');
        SQL

        puts prepared_statement

        response = @connection.exec(prepared_statement)
        Neo4j::Http::Results.parse(response || [])
      rescue => e
        raise_error(e.message, cypher, parameters)
      end

      def expand_parameters_for_set(cypher, parameters)
        if cypher.match(/SET node \+\= \$attributes/)
          new_set_syntax = "SET " + parameters[:attributes].map { |k,v| "node.#{k} = '#{v}'"}.join(", ")
          cypher.sub(/SET node \+\= \$attributes/, new_set_syntax)

        elsif cypher.match(/SET relationship \+\= \$relationship_attributes/)
          new_set_syntax = "SET " + parameters[:relationship_attributes].map { |k,v| "relationship.#{k} = '#{v}'"}.join(", ")
          cypher.sub(/SET relationship \+\= \$relationship_attributes/, new_set_syntax)

        else
          cypher
        end
      end

      # https://age.apache.org/age-manual/master/clauses/return.html#return-all-elements
      # AGE is different in that we have to separately declare each return as an agtype
      def return_syntax(cypher, returns)
        # Will attempt a crude parsing to extract RETURN variables
        # https://rubular.com/r/0TX7F3uTTfbUvW
        groups = cypher.match(/RETURN ((?:\w|,\s?)*)/i)

        if groups && groups[1]
          groups[1].split(",").map { |r| "\"#{r.delete(" ")}\" agtype"}.join(", ")
        else
          "v agtype"
        end
      end

      def connection(access_mode)
        build_connection(access_mode)
      end

      protected

      delegate :auth_token, :transaction_path, to: :@configuration
      def check_errors!(cypher, response, parameters)
        raise Neo4j::Http::Errors::InvalidConnectionUrl, response.status if response.status == 404
        if response.body["errors"].any? { |error| error["message"][/Routing WRITE queries is not supported/] }
          raise Neo4j::Http::Errors::ReadOnlyError
        end

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

      def build_connection(access_mode)
        PG::Connection.new(@configuration.uri)

        # https://neo4j.com/docs/http-api/current/actions/transaction-configuration/
        # headers = build_http_headers.merge({"access-mode" => access_mode})
        # Faraday.new(url: @configuration.uri, headers: headers, request: build_request_options) do |f|
        #   f.request :json # encode req bodies as JSON
        #   f.request :retry # retry transient failures
        #   f.response :json # decode response bodies as JSON
        # end
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
