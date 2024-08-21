require "forwardable"

module Neo4j
  module Http
    class Results
      def self.parse(results)
        if results.is_a?(Array)
          # Recuse on arrays
          return results.map { |a| self.parse(a) }
        elsif results.is_a?(Hash)
          # Recurse on hashes
          # Hoist ~properties key
          new_hash = {}
          results = results.except("~properties").merge(results["~properties"]) if results.key?("~properties")

          results.each_pair do |k,v|
            new_hash[k] = self.parse(v)
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
