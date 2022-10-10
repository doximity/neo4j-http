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
      create_node(from)
      create_node(to)

      relationship = Neo4j::Http::Relationship.new(label: "KNOWS", uuid: "RelationshipUuid", age: 21)
      create_relationship(from, relationship, to)

      updated_relationship = Neo4j::Http::Relationship.new(label: "KNOWS", uuid: "RelationshipUuid", age: 33)
      result = create_relationship(from, updated_relationship, to)

      expect(result["relationship"].keys).to eq(%w[uuid age _neo4j_meta_data])
      expect(result["relationship"]["uuid"]).to eq("RelationshipUuid")
      expect(result["relationship"]["age"]).to eq(33)

      rel = Neo4j::Http::Relationship.new(label: "KNOWS")
      relationships = client.find_relationships(relationship: rel, from: from, to: to)
      expect(relationships.count).to eq(1)
    end

    it "allows relationships with same labels between same nodes if primary key is set and different" do
      create_node(from)
      create_node(to)

      relationship_friend = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "uuid", uuid: "FriendUuid", how: "friend")
      edge_a = create_relationship(from, relationship_friend, to)

      relationship_colleague = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "uuid", uuid: "ColleagueUuid", how: "colleague")
      edge_b = create_relationship(from, relationship_colleague, to)

      expect(edge_a["relationship"]["uuid"]).to eq("FriendUuid")
      expect(edge_a["relationship"]["how"]).to eq("friend")

      expect(edge_b["relationship"]["uuid"]).to eq("ColleagueUuid")
      expect(edge_b["relationship"]["how"]).to eq("colleague")

      result = client.find_relationships(relationship: relationship, from: from, to: to)

      expect(result.count).to eq(2)
      expect(result[0]["from"]["uuid"]).to eq(result[1]["from"]["uuid"])
      expect(result[0]["to"]["uuid"]).to eq(result[1]["to"]["uuid"])
      expect(result[0]["relationship"]["how"]).not_to eq(result[1]["relationship"]["how"])
    end
  end

  describe "upsert_relationship_via_unwind" do
    it "creates a relationship between two nodes" do
      create_node(from)
      create_node(to)
      results = client.upsert_relationship(
        relationship: relationship,
        from: Neo4j::Http::Node.new(label: "Bot"),
        to: Neo4j::Http::Node.new(label: "Bot"),
        unwind: [
          {
            from: {
              uuid: "FromUuid"
            },
            to: {
              uuid: "ToUuid"
            },
            relationship: {}
          }
        ]
      )
      result = results.first
      expect(result.keys).to eq(["from", "to", "relationship"])
      expect(result["from"]["uuid"]).to eq("FromUuid")
      expect(result["to"]["uuid"]).to eq("ToUuid")
      expect(result["relationship"]).to be_kind_of(Hash)
      expect(result["relationship"].keys).to eq(%w[_neo4j_meta_data])
    end

    context "with create_nodes: true" do
      it "creates a missing node when it doesn't exist" do
        create_node(from)
        results = client.upsert_relationship(
          relationship: relationship,
          from: Neo4j::Http::Node.new(label: "Bot"),
          to: Neo4j::Http::Node.new(label: "Bot"),
          create_nodes: true,                                 # <-- this is the subject of the test
          unwind: [
            {
              from: {
                uuid: "FromUuid"
              },
              to: {
                uuid: "ToUuid"
              },
              relationship: {}
            }
          ]
        )
        result = results.first
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
        results = client.upsert_relationship(
          relationship: relationship,
          from: Neo4j::Http::Node.new(label: "Bot"),
          to: Neo4j::Http::Node.new(label: "Bot"),
          create_nodes: false,
          unwind: [
            {
              from: {
                uuid: "FromUuid"
              },
              to: {
                uuid: "ToUuid"
              }
            }
          ]
        )

        result = results.first
        expect(result).to be_nil
      end
    end

    it "Sets extra attributes on the relationship when given" do
      create_node(from)
      create_node(to)

      relationship = Neo4j::Http::Relationship.new(label: "KNOWS")
      results = client.upsert_relationship(
        relationship: relationship,
        from: Neo4j::Http::Node.new(label: "Bot"),
        to: Neo4j::Http::Node.new(label: "Bot"),
        unwind: [
          {
            from: {
              uuid: "FromUuid"
            },
            to: {
              uuid: "ToUuid"
            },
            relationship: {
              uuid: "RelationshipUuid",
              age: 21
            }
          }
        ]
      )
      verify_relationship(from, "KNOWS", to)

      result = results.first
      expect(result.keys).to eq(["from", "to", "relationship"])
      expect(result["from"]["uuid"]).to eq("FromUuid")
      expect(result["to"]["uuid"]).to eq("ToUuid")
      expect(result["relationship"]).to be_kind_of(Hash)
      expect(result["relationship"].keys).to eq(%w[uuid age _neo4j_meta_data])
      expect(result["relationship"]["uuid"]).to eq("RelationshipUuid")
      expect(result["relationship"]["age"]).to eq(21)
    end

    it "updates two different relationships on different nodes" do
      results = client.upsert_relationship(
        relationship: relationship,
        from: Neo4j::Http::Node.new(label: "Bot"),
        to: Neo4j::Http::Node.new(label: "Bot"),
        create_nodes: true,
        unwind: [
          {
            from: {
              uuid: "FromUuid"
            },
            to: {
              uuid: "ToUuid"
            },
            relationship: {}
          },
          {
            from: {
              uuid: "FromUuid2"
            },
            to: {
              uuid: "ToUuid2"
            },
            relationship: {
              foo: "bar"
            }
          }
        ]
      )

      verify_relationship(
        Neo4j::Http::Node.new(label: "Bot", uuid: "FromUuid"),
        "KNOWS",
        Neo4j::Http::Node.new(label: "Bot", uuid: "ToUuid")
      )

      verify_relationship(
        Neo4j::Http::Node.new(label: "Bot", uuid: "FromUuid2"),
        "KNOWS",
        Neo4j::Http::Node.new(label: "Bot", uuid: "ToUuid2")
      )
    end

    it "updates attributes on an existing relationship" do
      create_node(from)
      create_node(to)

      relationship = Neo4j::Http::Relationship.new(label: "KNOWS", uuid: "RelationshipUuid", age: 21)
      create_relationship(from, relationship, to)

      results = client.upsert_relationship(
        relationship: relationship,
        from: Neo4j::Http::Node.new(label: "Bot"),
        to: Neo4j::Http::Node.new(label: "Bot"),
        unwind: [
          {
            from: {
              uuid: "FromUuid"
            },
            to: {
              uuid: "ToUuid"
            },
            relationship: {
              uuid: "RelationshipUuid",
              age: 33
            }
          }
        ]
      )

      result = results.first

      expect(result["relationship"].keys).to eq(%w[uuid age _neo4j_meta_data])
      expect(result["relationship"]["uuid"]).to eq("RelationshipUuid")
      expect(result["relationship"]["age"]).to eq(33)

      rel = Neo4j::Http::Relationship.new(label: "KNOWS")
      relationships = client.find_relationships(relationship: rel, from: from, to: to)
      expect(relationships.count).to eq(1)
    end

    it "allows relationships with same labels between same nodes if primary key is set and different" do
      create_node(from)
      create_node(to)

      client.upsert_relationship(
        relationship: Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "uuid"),
        from: Neo4j::Http::Node.new(label: "Bot"),
        to: Neo4j::Http::Node.new(label: "Bot"),
        unwind: [
          {
            from: {
              uuid: "FromUuid"
            },
            to: {
              uuid: "ToUuid"
            },
            relationship: {
              primary_key_name: "uuid",
              uuid: "FriendUuid",
              how: "friend"
            }
          },
          {
            from: {
              uuid: "FromUuid"
            },
            to: {
              uuid: "ToUuid"
            },
            relationship: {
              primary_key_name: "uuid",
              uuid: "ColleagueUuid",
              how: "colleague"
            }
          }
        ]
      )

      results = Neo4j::Http::CypherClient.default.execute_cypher(
        "MATCH (from:Bot {uuid: $from})-[relationship:KNOWS]-(to:Bot {uuid: $to})
        RETURN from, to, relationship",
        from: "FromUuid",
        to: "ToUuid"
      )

      expect(results.length).to eq(2)

      edge_a = results.detect { |result| result["relationship"]["uuid"] == "FriendUuid"}
      edge_b = results.detect { |result| result["relationship"]["uuid"] == "ColleagueUuid"}

      expect(edge_a["relationship"]["uuid"]).to eq("FriendUuid")
      expect(edge_a["relationship"]["how"]).to eq("friend")

      expect(edge_b["relationship"]["uuid"]).to eq("ColleagueUuid")
      expect(edge_b["relationship"]["how"]).to eq("colleague")

      expect(results[0]["from"]["uuid"]).to eq(results[1]["from"]["uuid"])
      expect(results[0]["to"]["uuid"]).to eq(results[1]["to"]["uuid"])
      expect(results[0]["relationship"]["how"]).not_to eq(results[1]["relationship"]["how"])
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

  describe "delete_relationship_on_primary_key" do
    it "removes the correct relationship" do
      relationship1 = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "how", how: "friend")
      relationship2 = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "how", how: "colleague")
      client.upsert_relationship(relationship: relationship1, from: from, to: to, create_nodes: true)
      client.upsert_relationship(relationship: relationship2, from: from, to: to, create_nodes: true)

      expect(client.find_relationships(relationship: relationship, from: from, to: to).count).to eq(2)

      result = client.delete_relationship_on_primary_key(relationship: relationship2)
      expect(result.keys).to eq(["relationship"])

      rels = client.find_relationships(relationship: relationship, from: from, to: to)
      expect(rels.count).to eq(1)
      expect(rels.first["relationship"]["how"]).to eq("friend")
    end

    it "doesn't delete if primary key is  missing" do
      relationship1 = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "how", how: "friend")
      relationship2 = Neo4j::Http::Relationship.new(label: "KNOWS", primary_key_name: "how", how: "colleague")
      client.upsert_relationship(relationship: relationship1, from: from, to: to, create_nodes: true)
      client.upsert_relationship(relationship: relationship2, from: from, to: to, create_nodes: true)

      expect(client.find_relationships(relationship: relationship, from: from, to: to).count).to eq(2)

      result = client.delete_relationship_on_primary_key(relationship: relationship)
      expect(result).to be_nil

      expect(client.find_relationships(relationship: relationship, from: from, to: to).count).to eq(2)
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

  def create_relationship(from, relationship, to)
    Neo4j::Http::RelationshipClient.default.upsert_relationship(from: from, relationship: relationship, to: to)
  end
end
