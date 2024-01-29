# frozen_string_literal: true

require "spec_helper"

RSpec.describe Neo4j::Http::BatchRelationshipClient do
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

      # Inspect the statement payload before executing
      expect(result[:statement]).to match(/MATCH \(from:Bot \{uuid: \$from\.uuid\}\)/)
      expect(result[:parameters][:from]).to eq(from)
      expect(result[:parameters][:to]).to eq(to)
      expect(result[:parameters][:relationship]).to eq(relationship)
      expect(result[:parameters][:relationship_attributes]).to eq({})

      # Batch upsert
      Neo4j::Http::Client.in_batch do |tx|
        tx.upsert_relationship(relationship: relationship, from: from, to: to)
      end

      # Verify insert
      result = Neo4j::Http::Client.execute_cypher "MATCH (:Bot)-[r:KNOWS]-(:Bot) RETURN r LIMIT 1"
      expect(result.first["r"]).to be_present
    end
  end

  describe "delete_relationship" do
    it "Removes the relationship between the nodes" do
      relationship = Neo4j::Http::Relationship.new(label: "KNOWS")

      # Insert the relationship
      Neo4j::Http::Client.upsert_relationship(relationship: relationship, from: from, to: to, create_nodes: true)

      # Verify insert
      result = Neo4j::Http::Client.execute_cypher "MATCH (:Bot)-[r:KNOWS]-(:Bot) RETURN r LIMIT 1"
      expect(result.length).to eq(1)

      # Batch delete the relationship
      Neo4j::Http::Client.in_batch do |tx|
        tx.delete_relationship(relationship: relationship, from: from, to: to)
      end

      # Verify delete
      result = Neo4j::Http::Client.execute_cypher "MATCH (:Bot)-[r:KNOWS]-(:Bot) RETURN r LIMIT 1"
      expect(result.length).to eq(0)
    end
  end

  describe "delete_relationship_on_primary_key" do
    it "removes the correct relationship" do
      relationship1 = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "how", how: "friend")
      relationship2 = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "how", how: "colleague")
      # Insert the relationships
      Neo4j::Http::Client.upsert_relationship(relationship: relationship1, from: from, to: to, create_nodes: true)
      Neo4j::Http::Client.upsert_relationship(relationship: relationship2, from: from, to: to, create_nodes: true)

      # Verify the inserts
      expect(client.find_relationships(relationship: relationship, from: from, to: to).count).to eq(2)

      # Inspect the statement payload before executing
      result = client.delete_relationship_on_primary_key(relationship: relationship2)
      expect(result[:statement]).to match(/MATCH \(\) - \[relationship:KNOWS \{how: \$relationship\.how\}\] - \(\)/)
      expect(result[:parameters][:relationship]).to eq(relationship2)

      # Batch delete the relationship
      Neo4j::Http::Client.in_batch do |tx|
        tx.delete_relationship_on_primary_key(relationship: relationship2)
      end

      # Verify the delete
      result = Neo4j::Http::Client.execute_cypher "MATCH (:Bot)-[r:KNOWS { how: 'friend'}]-(:Bot) RETURN r LIMIT 1"
      expect(result.length).to eq(1)

      result = Neo4j::Http::Client.execute_cypher "MATCH (:Bot)-[r:KNOWS { how: 'colleague'}]-(:Bot) RETURN r LIMIT 1"
      expect(result.length).to eq(0)
    end
  end

  def create_node(node)
    Neo4j::Http::NodeClient.default.upsert_node(node)
  end

  def create_relationship(from, relationship, to)
    Neo4j::Http::RelationshipClient.default.upsert_relationship(from: from, relationship: relationship, to: to)
  end
end
