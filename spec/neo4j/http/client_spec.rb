# frozen_string_literal: true

require "spec_helper"

RSpec.describe Neo4j::Http::Client, type: :uses_neo4j do
  let(:cypher_client) { double(Neo4j::Http::CypherClient) }
  let(:node_client) { double(Neo4j::Http::NodeClient) }
  let(:relationship_client) { double(Neo4j::Http::RelationshipClient) }
  subject(:client) { described_class.new(cypher_client, node_client, relationship_client) }

  describe "class methods" do
    it "has the expected set of methods" do
      expected_methods = described_class::CLIENT_METHODS + [:default, :in_batch]
      expect(described_class.methods(false)).to match_array(expected_methods)
    end

    described_class::CLIENT_METHODS.each do |method|
      it "delegates the #{method} to the default instance" do
        client_double = double(described_class)
        allow(described_class).to receive(:default).and_return(client_double)
        allow(client_double).to receive(method).and_return("received")
        expect(described_class.public_send(method)).to eq("received")
      end
    end
  end

  describe "cypher methods" do
    it "delegates to the cypher client" do
      allow(cypher_client).to receive(:execute_cypher).with(:args)
      client.execute_cypher(:args)
      expect(cypher_client).to have_received(:execute_cypher).with(:args)
    end
  end

  describe "node methods" do
    described_class::NODE_CLIENT_METHODS.each do |method|
      it "delegates #{method} to the node client" do
        allow(node_client).to receive(method).with(:args)
        client.public_send(method, :args)
        expect(node_client).to have_received(method).with(:args)
      end
    end
  end

  describe "relationship methods" do
    described_class::RELATIONSHIP_CLIENT_METHODS.each do |method|
      it "delegates #{method} to the relationship client" do
        allow(relationship_client).to receive(method).with(:args)
        client.public_send(method, :args)
        expect(relationship_client).to have_received(method).with(:args)
      end
    end
  end

  describe "in_batch" do
    it "runs single statement in batch client" do
      described_class.in_batch do |tx|
        tx.upsert_node(Neo4j::Http::Node.new(label: "Foo", uuid: "0abbf43f-6fbd-4176-8db4-a3c7fdd8bb17"))
      end

      result = described_class.execute_cypher("MATCH (n:Foo { uuid: '0abbf43f-6fbd-4176-8db4-a3c7fdd8bb17'}) RETURN n LIMIT 1")
      expect(result.first["n"]["uuid"]).to eq("0abbf43f-6fbd-4176-8db4-a3c7fdd8bb17")
    end

    it "runs statements in batch client" do
      described_class.in_batch do |tx|
        [
          tx.upsert_node(Neo4j::Http::Node.new(label: "Foo", uuid: "0abbf43f-6fbd-4176-8db4-a3c7fdd8bb17")),
          tx.upsert_node(Neo4j::Http::Node.new(label: "Bar", uuid: "05d30cd1-020f-4693-8487-28018862690e"))
        ]
      end

      result = described_class.execute_cypher("MATCH (n:Foo { uuid: '0abbf43f-6fbd-4176-8db4-a3c7fdd8bb17'}) RETURN n LIMIT 1")
      expect(result.first["n"]["uuid"]).to eq("0abbf43f-6fbd-4176-8db4-a3c7fdd8bb17")

      result = described_class.execute_cypher("MATCH (n:Bar { uuid: '05d30cd1-020f-4693-8487-28018862690e'}) RETURN n LIMIT 1")
      expect(result.first["n"]["uuid"]).to eq("05d30cd1-020f-4693-8487-28018862690e")
    end

    it "yields batch client" do
      described_class.in_batch do |tx|
        expect(tx).to eq(::Neo4j::Http::BatchClient)
        [] # this is a no op - just want to check the yielded object
      end
    end
  end
end
