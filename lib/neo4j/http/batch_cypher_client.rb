# frozen_string_literal: true

require "forwardable"
require "faraday"
require "faraday/retry"
require "faraday_middleware"

module Neo4j
  module Http
    class BatchCypherClient < CypherClient
      # Each statement should be Hash with statement and parameters keys e.g.
      #   {
      #     statement: "MATCH (n:User { name: $name }) RETURN n",
      #     parameters: { name: "Ben" }
      #   }
      # https://neo4j.com/docs/http-api/current/actions/execute-multiple-statements/
      def execute_cypher(statements = [])
        statements = [statements] if statements.is_a?(Hash) # equivalent to Array.wrap

        request_body = {
          statements: statements.map do |statement|
            {
              statement: statement[:statement],
              parameters: statement[:parameters].as_json
            }
          end
        }

        @connection = @injected_connection || connection("WRITE")
        response = @connection.post(transaction_path, request_body)
        results = check_errors!(statements, response)

        results.map do |result|
          Neo4j::Http::Results.parse(result || {})
        end
      end
    end
  end
end
