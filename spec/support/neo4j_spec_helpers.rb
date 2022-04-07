# frozen_string_literal: true

module Neo4jSpecHelpers
  extend ActiveSupport::Concern

  def clean_neo4j_database
    cypher = "MATCH (n) DETACH DELETE n"
    Neo4j::Http::CypherClient.default.execute_cypher(cypher)
  end
end

RSpec.configure do |c|
  c.before(:example, type: :uses_neo4j) do
    clean_neo4j_database
  end
end
