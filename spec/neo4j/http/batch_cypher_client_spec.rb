# frozen_string_literal: true

require "spec_helper"
require "faraday"

RSpec.describe Neo4j::Http::BatchCypherClient, type: :uses_neo4j do
  subject(:client) { described_class.default }

  describe "execute_batch_cypher" do
    it "executes all statments" do
      statement1 = "MERGE (node:Test {uuid: 'Uuid1', name: 'Foo'}) return node"
      statement2 = "MERGE (node:Test {uuid: 'Uuid2', name: 'Bar'}) return node"
      statement3 = "MERGE (node:Test {uuid: 'Uuid3', name: $name}) return node"
      statement4 = "MERGE (node:Test {uuid: 'Uuid4', name: $name}) return node"

      results = client.execute_cypher([
        {
          statement: statement1,
          parameters: nil
        },
        {
          statement: statement2,
          parameters: {}
        },
        {
          statement: statement3,
          parameters: {name: "Baz"}
        },
        {
          statement: statement4,
          parameters: {name: "Qux"}
        }
      ])

      expect(results[0][0]["node"]["name"]).to eq("Foo")
      expect(results[1][0]["node"]["name"]).to eq("Bar")
      expect(results[2][0]["node"]["name"]).to eq("Baz")
      expect(results[3][0]["node"]["name"]).to eq("Qux")
    end

    it "handles error and rolls back" do
      good_statement = "MERGE (node:Test {uuid: 'Uuid1', name: 'Foo'}) return node"
      bad_statement = "MERGE (node:Test {uuid: 'Uuid2', name: 'Bar'}) BAD SYNTAX"
      good_statement2 = "MERGE (node:Test {uuid: 'Uuid3', name: 'Baz'}) return node"

      expect {
        client.execute_cypher([
          {
            statement: good_statement,
            parameters: {}
          },
          {
            statement: bad_statement,
            parameters: {}
          },
          {
            statement: good_statement2,
            parameters: {}
          }
        ])
      }.to raise_error Neo4j::Http::Errors::Neo::ClientError::Statement::SyntaxError

      results = Neo4j::Http::Client.execute_cypher("MATCH (node:Test { uuid: 'Uuid1' }) return node")
      expect(results).to be_empty

      results = Neo4j::Http::Client.execute_cypher("MATCH (node:Test { uuid: 'Uuid3' }) return node")
      expect(results).to be_empty
    end
  end
end
