# frozen_string_literal: true

require "spec_helper"

RSpec.describe Neo4j::Http::NodeClient, type: :uses_neo4j do
  subject(:client) { described_class.default }
  let(:cypher_client) { Neo4j::Http::CypherClient.default }

  describe "upsert_node" do
    it "creates a node" do
      uuid = "MyUuid"
      node_in = Neo4j::Http::Node.new(label: "Test", uuid: uuid, name: "Foo")
      node = client.upsert_node(node_in)
      expect(node["uuid"]).to eq(uuid)
      expect(node["name"]).to eq("Foo")
      expect(node["_neo4j_meta_data"]).not_to be_nil
      expect(node["_neo4j_meta_data"]["id"]).not_to be_nil

      results = cypher_client.execute_cypher("MATCH (node:Test {uuid: $uuid}) RETURN node", uuid: uuid)
      expect(results.length).to eq(1)
      node = results&.first&.fetch("node", nil)
      expect(node).not_to be_nil
      expect(node["name"]).to eq("Foo")
    end

    it "updates the existing node" do
      uuid = "MyUuid"
      node_in = Neo4j::Http::Node.new(label: "Test", uuid: uuid, name: "Foo")
      node1 = client.upsert_node(node_in)
      expect(node1["uuid"]).to eq(uuid)
      expect(node1["name"]).to eq("Foo")
      expect(node1["_neo4j_meta_data"]).not_to be_nil
      expect(node1["_neo4j_meta_data"]["id"]).not_to be_nil

      node_in = Neo4j::Http::Node.new(label: "Test", uuid: uuid, name: "Bar")
      node2 = client.upsert_node(node_in)
      expect(node2["uuid"]).to eq(uuid)
      expect(node2["name"]).to eq("Bar")
      expect(node2["_db_id"]).to eq(node1["_db_id"])
      expect(node2["_neo4j_meta_data"]).not_to be_nil
      expect(node2["_neo4j_meta_data"]["id"]).to eq(node1["_neo4j_meta_data"]["id"])

      results = cypher_client.execute_cypher("MATCH (node:Test {uuid: $uuid}) RETURN node", uuid: uuid)
      expect(results.length).to eq(1)
    end
  end

  describe "find_node_by" do
    it "finds a node by the attributes given" do
      create_node(uuid: "Uuid2", name: "Bar")
      create_node(uuid: "Uuid1", name: "Foo")

      node = client.find_node_by(label: "Test", uuid: "Uuid1")

      expect(node).not_to be_nil
      expect(node["name"]).to eq("Foo")
    end

    it "returns nil when no node is found" do
      node = client.find_node_by(label: "Test", uuid: "MyUuid")
      expect(node).to be_nil
    end
  end

  describe "find_nodes_by" do
    it "finds nodes by the attributes given" do
      create_node(uuid: "Uuid1", name: "Foo")
      create_node(uuid: "Uuid2", name: "Bar")
      create_node(uuid: "Uuid3", name: "Baz")

      nodes = client.find_nodes_by(label: "Test", attributes: { uuid: ["Uuid1", "Uuid3"] })

      expect(nodes.length).to eq(2)
      names = nodes.map { |node| node["name"] }
      expect(names).to match_array(["Foo", "Baz"])
    end

    it "returns nil when no node is found" do
      node = client.find_node_by(label: "Test", attributes: { uuid: "MyUuid" })
      expect(node).to be_nil
    end
  end

  def create_node(attributes = {})
    node = Neo4j::Http::Node.new(label: "Test", **attributes)
    client.upsert_node(node)
  end
end
