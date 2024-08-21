# frozen_string_literal: true

require "spec_helper"

# Examples taken from
# https://docs.aws.amazon.com/neptune/latest/userguide/access-graph-opencypher-queries.html
RSpec.describe Neo4j::Http::Results, type: :uses_neo4j do
  it "returns node response" do
    results = JSON.parse %q(
      {
        "results": [
          {
            "a": {
              "~id": "22",
              "~entityType": "node",
              "~labels": [
                "airport"
              ],
              "~properties": {
                "desc": "Seattle-Tacoma",
                "lon": -122.30899810791,
                "runways": 3,
                "type": "airport",
                "country": "US",
                "region": "US-WA",
                "lat": 47.4490013122559,
                "elev": 432,
                "city": "Seattle",
                "icao": "KSEA",
                "code": "SEA",
                "longest": 11901
              }
            }
          }
        ]
      }
    )

    output = described_class.parse(results["results"])
    expected = {
      "desc" => "Seattle-Tacoma",
      "lon" => -122.30899810791,
      "runways" => 3,
      "type" => "airport",
      "country" => "US",
      "region" => "US-WA",
      "lat" => 47.4490013122559,
      "elev" => 432,
      "city" => "Seattle",
      "icao" => "KSEA",
      "code" => "SEA",
      "longest" => 11901,
    }
    expect(output[0]["a"]).to match(expected)
  end

  it "returns relationship response" do
    results = JSON.parse %q(
      {
        "results": [
          {
            "r": {
              "~id": "7389",
              "~entityType": "relationship",
              "~start": "22",
              "~end": "151",
              "~type": "route",
              "~properties": {
                "dist": 956
              }
            }
          }
        ]
      }
    )

    output = described_class.parse(results["results"])
    expected = {
     "dist"=>956,
    }
    expect(output[0]["r"]).to eq(expected)
  end

  it "returns value response" do
    results = JSON.parse %q(
      {
        "results": [
          {
            "count(a)": 121
          }
        ]
      }
    )

    output = described_class.parse(results["results"])
    expect(output[0]["count(a)"]).to eq(121)
  end

  it "returns user network query results" do
    results = [
      {
        "colleagues" => [
          [{
            "~id" => "457e8e96-3cbc-4122-97a5-4dc9fe32dbc4",
            "~entityType" => "node",
            "~labels" => ["User"],
            "~properties" => {
              "name" => "Dolores Abernathy", "uuid" => "USER", "specialty" => "Immunology", "city" => "Westworld", "state" => "Utah"
            }
          }, {
            "~id" => "387fb59e-9e7d-4507-ba17-7de691d3e13e",
            "~entityType" => "relationship",
            "~start" => "457e8e96-3cbc-4122-97a5-4dc9fe32dbc4",
            "~end" => "48e1f64c-48d2-421f-8b10-38ebd58df761",
            "~type" => "COLLEAGUES_WITH",
            "~properties" => {
              "state" => "invited"
            }
          }, {
            "~id" => "48e1f64c-48d2-421f-8b10-38ebd58df761",
            "~entityType" => "node",
            "~labels" => ["User"],
            "~properties" => {
              "name" => "Maeve Millay", "uuid" => "OTHER-USER", "specialty" => "Immunology", "city" => "Westworld", "state" => "Utah"
            }
          }]
        ], "medschool_classmates" => nil, "co_residents" => nil, "co_workers" => nil, "investigator_of" => nil, "full_name" => "Maeve Millay", "co_fellows" => nil, "co_authors" => nil, "paschool_classmates" => nil, "user_uuid" => "OTHER-USER"
      }
    ]

    output = described_class.parse(results)
    expect(output[0]["colleagues"][0][0]["name"]).to eq("Dolores Abernathy")
    expect(output[0]["colleagues"][0][1]["state"]).to eq("invited")
    expect(output[0]["colleagues"][0][2]["name"]).to eq("Maeve Millay")
  end
end
