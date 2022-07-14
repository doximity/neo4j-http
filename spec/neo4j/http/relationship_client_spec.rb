# frozen_string_literal: true

require "spec_helper"

RSpec.describe Neo4j::Http::RelationshipClient do
  subject(:client) { described_class.default }
  before(:each) { clean_neo4j_database }

  let(:from) { Neo4j::Http::Node.new(label: "Bot", uuid: "FromUuid", name: "Foo") }
  let(:to) { Neo4j::Http::Node.new(label: "Bot", uuid: "ToUuid", name: "Bar") }
  let(:relationship) { Neo4j::Http::Relationship.new(label: "KNOWS") }

  describe "upsert_relationship" do
    it "creates a relationship between two nodes" do
      create_node(from)
      create_node(to)
      result = client.upsert_relationship(relationship: relationship, from: from, to: to)
      expect(result.keys).to eq(["from", "to", "relationship"])
      expect(result["from"]["uuid"]).to eq("FromUuid")
      expect(result["to"]["uuid"]).to eq("ToUuid")
      expect(result["relationship"]).to be_kind_of(Hash)
      expect(result["relationship"].keys).to eq(%w[_neo4j_meta_data])
    end

    context "with create_nodes: true" do
      it "creates a missing node when it doesn't exist" do
        create_node(from)
        result = client.upsert_relationship(relationship: relationship, from: from, to: to, create_nodes: true)
        expect(result.keys).to eq(["from", "to", "relationship"])
        expect(result["from"]["uuid"]).to eq("FromUuid")
        expect(result["to"]["uuid"]).to eq("ToUuid")
        expect(result["relationship"]).to be_kind_of(Hash)
        expect(result["relationship"].keys).to eq(%w[_neo4j_meta_data])

        results = Neo4j::Http::CypherClient.default.execute_cypher("MATCH (node:Bot{uuid: 'ToUuid'}) return node")
        node = results.first["node"]
        expect(node["uuid"]).to eq("ToUuid")
      end
    end

    context "with create_nodes: false" do
      it "fails when the nodes do not exist" do
        create_node(from)
        result = client.upsert_relationship(relationship: relationship, from: from, to: to, create_nodes: false)

        expect(result).to be_nil
      end
    end

    it "Sets extra attributes on the relationship when given" do
      create_node(from)
      create_node(to)

      relationship = Neo4j::Http::Relationship.new(label: "KNOWS", uuid: "RelationshipUuid", age: 21)
      result = client.upsert_relationship(relationship: relationship, from: from, to: to)
      verify_relationship(from, "KNOWS", to)

      expect(result.keys).to eq(["from", "to", "relationship"])
      expect(result["from"]["uuid"]).to eq("FromUuid")
      expect(result["to"]["uuid"]).to eq("ToUuid")
      expect(result["relationship"]).to be_kind_of(Hash)
      expect(result["relationship"].keys).to eq(%w[uuid age _neo4j_meta_data])
      expect(result["relationship"]["uuid"]).to eq("RelationshipUuid")
      expect(result["relationship"]["age"]).to eq(21)
    end

    it "updates attributes on an existing relationship" do
    end
  end

  describe "find_relationship" do
    it "finds an existing relationship" do
      relationship = Neo4j::Http::Relationship.new(label: "KNOWS", value: 42.43)
      result = client.upsert_relationship(relationship: relationship, from: from, to: to, create_nodes: true)
      expect(result.keys).to eq(["from", "to", "relationship"])

      result = client.find_relationship(relationship: relationship, from: from, to: to)
      expect(result.keys).to eq(["from", "to", "relationship"])
      expect(result["from"]["uuid"]).to eq("FromUuid")
      expect(result["to"]["uuid"]).to eq("ToUuid")
      expect(result["relationship"]["value"]).to eq(42.43)
    end
  end

  describe "delete_relationship" do
    it "Removes the relationship between the nodes" do
      relationship = Neo4j::Http::Relationship.new(label: "KNOWS")
      result = client.upsert_relationship(relationship: relationship, from: from, to: to, create_nodes: true)
      expect(result.keys).to eq(["from", "to", "relationship"])

      result = client.find_relationship(relationship: relationship, from: from, to: to)
      expect(result.keys).to eq(["from", "to", "relationship"])

      result = client.delete_relationship(relationship: relationship, from: from, to: to)
      expect(result.keys).to eq(["from", "to"])

      result = client.find_relationship(relationship: relationship, from: from, to: to)
      expect(result).to be_nil
    end
  end

  def verify_relationship(from, relationship, to)
    results = Neo4j::Http::CypherClient.default.execute_cypher(
      "MATCH (from:Bot {uuid: $from})-[relationship:#{relationship}]-(to:Bot {uuid: $to})
      RETURN from, to, relationship",
      from: from.key_value,
      to: to.key_value
    )
    result = results.first

    expect(result.keys).to eq(%w[from to relationship])
    expect(result["from"]["uuid"]).to eq(from.uuid)
    expect(result["to"]["uuid"]).to eq(to.uuid)
  end

  def create_node(node)
    Neo4j::Http::NodeClient.default.upsert_node(node)
  end
end
