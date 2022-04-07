require "forwardable"

module Neo4j
  module Http
    class Results
      # Example result set:
      # [{"columns"=>["n"], "data"=>[{"row"=>[{"name"=>"Foo", "uuid"=>"8c7dcfda-d848-4937-a91a-2e6debad2dd6"}], "meta"=>[{"id"=>242, "type"=>"node", "deleted"=>false}]}]}]
      #
      def self.parse(results)
        columns = results["columns"]
        data = results["data"]

        data.map do |result|
          row = result["row"] || []
          meta = result["meta"] || []
          compacted_data = row.each_with_index.map do |attributes, index|
            row_meta = meta[index] || {}
            attributes["_neo4j_meta_data"] = row_meta if attributes.kind_of?(Hash)
            attributes
          end

          columns.zip(compacted_data).to_h.with_indifferent_access
        end
      end
    end
  end
end
