module Neo4j
  module Http
    module Errors
      Neo4jError = Class.new(StandardError)
      InvalidConnectionUrl = Class.new(Neo4jError)
      Neo4jCodedError = Class.new(Neo4jError)

      # These are specific Errors Neo4j can raise
      module Neo
        module ClientError
          module Statement
            SyntaxError = Class.new(Neo4jCodedError)
          end

          module Schema
            ConstraintValidationFailed = Class.new(Neo4jCodedError)
          end
        end
      end
    end
  end
end
