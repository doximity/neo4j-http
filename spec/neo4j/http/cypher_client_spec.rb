# frozen_string_literal: true

require "spec_helper"

RSpec.describe Neo4j::Http::CypherClient, type: :uses_neo4j do
  subject(:client) { described_class.default }

  describe "connection" do
    it "uses the request timeout option when provided" do
      config = Neo4j::Http::Configuration.new
      config.request_timeout_in_seconds = 42
      client = described_class.new(config)
      expect(client.connection.options.timeout).to eq(42)
    end

    it "defaults to having no request timeout" do
      expect(client.connection.options.timeout).to be_nil
    end
  end

  describe "execute_cypher" do
    it "executes arbitrary cypher commands" do
      results = client.execute_cypher("MERGE (node:Test {uuid: 'Uuid1', name: 'Foo'}) return node")
      expect(results.length).to eq(1)
      node = results.first["node"]
      expect(node["uuid"]).to eq("Uuid1")

      results = client.execute_cypher("MERGE (node:Test {uuid: 'Uuid2', name: 'Bar'}) return node")
      expect(results.length).to eq(1)
      node = results.first["node"]
      expect(node["uuid"]).to eq("Uuid2")

      results = client.execute_cypher("MATCH (node:Test {uuid: 'Uuid1'}) return node")
      expect(results.length).to eq(1)
      node = results.first["node"]
      expect(node["uuid"]).to eq("Uuid1")

      results = client.execute_cypher("MATCH (node:Test) return node")
      expect(results.length).to eq(2)
      uuids = results.map { |result| result["node"]["uuid"] }
      expect(uuids).to match_array(%w[Uuid1 Uuid2])
      names = results.map { |result| result["node"]["name"] }
      expect(names).to match_array(%w[Foo Bar])

      results = client.execute_cypher("MATCH (node:Test {uuid: 'Uuid1'}) DETACH DELETE node return node")
      expect(results.length).to eq(1)
      expect(results.first["node"].keys).to eq(["_neo4j_meta_data"])

      results = client.execute_cypher("MATCH (node:Test {uuid: 'Uuid1'}) return node")
      expect(results.length).to eq(0)
    end
  end
end
