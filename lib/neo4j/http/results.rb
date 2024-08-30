require "forwardable"

module Neo4j
  module Http
    class Results
      # [{"n"=>"{\"id\": 844424930131972, \"label\": \"User\", \"properties\": {\"name\": \"ben\"}}::vertex"}]
      def self.parse(results)
        x = results.map do |result|

          response = result.dup
          result.each_pair do |key, value|
            value.slice!("::vertex")
            value.slice!("::edge")
            response[key] = JSON.parse(value)
          end
          response
        end

        hoist_properties(x)
      end

      def self.hoist_properties(results)
        if results.is_a?(Array)
          # Recuse on arrays
          return results.map { |a| self.hoist_properties(a) }
        elsif results.is_a?(Hash)
          # Recurse on hashes
          # Hoist ~properties key
          new_hash = {}
          results = results.merge(results["properties"]) if results.key?("properties")

          results.each_pair do |k,v|
            new_hash[k] = self.hoist_properties(v)
          end
          return new_hash
        else
          # Primative value
          return results
        end
      end
    end
  end
end
