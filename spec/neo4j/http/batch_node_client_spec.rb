# frozen_string_literal: true

require "spec_helper"

RSpec.describe Neo4j::Http::BatchNodeClient, type: :uses_neo4j do
  subject(:client) { described_class.default }
  let(:cypher_client) { Neo4j::Http::CypherClient.default }

  describe "upsert_node" do
    it "creates a node" do
      uuid = "MyUuid"
      # Inspect the statement payload before executing
      node_in = Neo4j::Http::Node.new(label: "Test", uuid: uuid, name: "Foo")
      node = client.upsert_node(node_in)

      expect(node[:statement]).to match(/MERGE \(node:Test \{uuid: \$key_value\}\)/)
      expect(node[:parameters][:key_value]).to eq("MyUuid")
      expect(node[:parameters][:attributes][:name]).to eq("Foo")

      # Insert the node
      Neo4j::Http::Client.in_batch do |tx|
        tx.upsert_node(node_in)
      end

      # Verify the insert
      results = cypher_client.execute_cypher("MATCH (node:Test {uuid: $uuid}) RETURN node", uuid: uuid)
      expect(results.length).to eq(1)
      node = results&.first&.fetch("node", nil)
      expect(node).not_to be_nil
      expect(node["name"]).to eq("Foo")
    end

    it "updates the existing node" do
      uuid = "MyUuid"
      # Insert the node
      node1 = create_node({uuid: uuid, name: "Foo"})

      expect(node1["uuid"]).to eq(uuid)
      expect(node1["name"]).to eq("Foo")
      expect(node1["_neo4j_meta_data"]).not_to be_nil
      expect(node1["_neo4j_meta_data"]["id"]).not_to be_nil

      # Batch upsert the node
      node_in = Neo4j::Http::Node.new(label: "Test", uuid: uuid, name: "Bar")
      Neo4j::Http::Client.in_batch do |tx|
        tx.upsert_node(node_in)
      end

      # Verify the change
      results = cypher_client.execute_cypher("MATCH (node:Test {uuid: $uuid}) RETURN node", uuid: uuid)
      expect(results.length).to eq(1)
      expect(results.first["node"]["name"]).to eq("Bar")
    end
  end

  describe "delete_node" do
    it "deletes a node" do
      uuid = "MyUuid"
      # Inspect the statement payload before executing
      create_node({uuid: uuid, name: "Foo"})
      node_in = Neo4j::Http::Node.new(label: "Test", uuid: uuid)

      # Batch delete the node
      Neo4j::Http::Client.in_batch do |tx|
        tx.delete_node(node_in)
      end

      # Verify deletion
      results = cypher_client.execute_cypher("MATCH (node:Test {uuid: $uuid}) RETURN node", uuid: uuid)
      expect(results.length).to eq(0)
    end
  end

  def create_node(attributes = {})
    node = Neo4j::Http::Node.new(label: "Test", **attributes)
    Neo4j::Http::Client.upsert_node(node)
  end
end
