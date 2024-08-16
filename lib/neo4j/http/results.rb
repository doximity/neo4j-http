require "forwardable"

module Neo4j
  module Http
    class Results
      # And return result from this gem
      # [{"u1"=>
      #   {"specialty"=>"Colon & Rectal Surgery",
      #     "city"=>"Staten Island",
      #     "credentials"=>"DO",
      #     "profile_url"=>"https://doximity.qa-skaur-1.doximity-staging.services/profiles/f3dff658-3c79-4227-878b-8cf56a6d32c9",
      #     "last_name"=>"test",
      #     "lon"=>-74.1780014038086,
      #     "state"=>"New York",
      #     "uuid"=>"f3dff658-3c79-4227-878b-8cf56a6d32c9",
      #     "legacy_elasticsearch_user_id"=>5532386,
      #     "first_name"=>"samm",
      #     "lat"=>40.61940002441406,
      #     "subspecialties"=>"General Colon & Rectal Surgery, Clinical Pharmacology, Clinical Informatics",
      #     "_neo4j_meta_data"=>{"id"=>0, "type"=>"node", "deleted"=>false}}},
      # {"u1"=>
      #   {"specialty"=>"Other MD/DO",
      #     "city"=>"Marina",
      #     "profile_url"=>"https://doximity.qa-skaur-1.doximity-staging.services/profiles/f40908ec-2f4e-4a49-97bc-68e70f341f9d",
      #     "credentials"=>"MD",
      #     "last_name"=>"kaur",
      #     "lon"=>-121.80216979980469,
      #     "state"=>"California",
      #     "uuid"=>"f40908ec-2f4e-4a49-97bc-68e70f341f9d",
      #     "legacy_elasticsearch_user_id"=>5532349,
      #     "first_name"=>"sandip",
      #     "lat"=>36.68439865112305,
      #     "subspecialties"=>"Other MD/DO",
      #     "_neo4j_meta_data"=>{"id"=>1, "type"=>"node", "deleted"=>false}}}]

      # Neptune Example result set
      # {
      #   "results": [{
      #       "n1": {
      #         "~id": "7b3caa7b-4187-4689-be1f-8d8c924a23df",
      #         "~entityType": "node",
      #         "~labels": ["User"],
      #         "~properties": {
      #           "uuid": "abc123"
      #         }
      #       }
      #     }, {
      #       "n1": {
      #         "~id": "28b2bc2a-03d4-415d-9f37-bd4b9420e449",
      #         "~entityType": "node",
      #         "~labels": ["User"],
      #         "~properties": {
      #           "uuid": "def456"
      #         }
      #       }
      #     }]
      def self.parse(results)
        results.map do |result|
          entries = {}
          result.each_pair do |key, value|
            if value.is_a?(Hash)
              meta = {
                "id" => value["~id"],
                "type" => value["~entityType"],
              }
              entries[key] = (value["~properties"] || {}).merge({ "_neo4j_meta_data" => meta }).with_indifferent_access
            else
              entries[key] = value
            end
          end
          entries
        end
      end
    end
  end
end
