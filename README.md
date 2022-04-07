# Neo4j::Http

The `Neo4j::Http` gem provides `Neo4j::Http::Client` as a thin wrapper around the [Neo4j HTTP API](https://neo4j.com/docs/http-api/current/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'neo4j-http'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install neo4j-http

## Configuration

The client is configured by default via a set of environment variables from `[Neo4j::Http::Configuration](https://github.com/doximity/neo4j-http/blob/master/lib/neo4j/http/configuration.rb)`:

* `NEO4J_URL`  - The base URL to connect to Neo4j at
* `NEO4J_USER` - The user name to use when authenticating to neo4j
* `NEO4J_PASSWORD` - The password of the user to be used for authentication
* `NEO4J_DATABASE` - The database name to be used when connectiong.  By default this will be nil and the path used for connecting to Neo4j wil be `/db/data/transaction/commit` to make it compliant with v3.5 of neo4j
* `NEO4J_HTTP_USER_AGENT` - The user agent name provided in the request - defaults to `Ruby Neo4j Http Client`
* `NEO4J_REQUEST_TIMEOUT_IN_SECONDS` - The number of seconds for the http request to time out if provided, defaults to nil

These configuration values can also be set during intialization like:

```
Neo4j::Http.configure do |config|
  config.request_timeout_in_secods = 42
end
```

## Usage

The core interface can be directly accessed on `Neo4::Http::Client`:

```
# Execute arbitrary cypher commands
Neo4j::Http::Client.execute_cypher('MATCH n:User{id: id} return n LIMIT 25', id: 42)

# Upsert, find and delete nodes
node = Neo4j::Http::Node.new(label: "User", uuid: SecureRandom.uuid)
Neo4j::Http::Client.upsert_node(node)
Neo4j::Http::Client.find_node_by(label: "User", uuid: node.uuid)
Neo4j::Http::Client.find_nodes_by(label: "User", name: "Testing")
Neo4j::Http::Client.delete_node(node)

# Create a new relationship, also creating the nodes if they do not exist
user1 = Neo4j::Http::Node.new(label: "User", uuid: SecureRandom.uuid)
user2 = Neo4j::Http::Node.new(label: "User", uuid: SecureRandom.uuid)
relationship = Neo4j::Http::Relationship.new(label: "KNOWS")
Neo4j::Http::Client.upsert_relationship(relationship: relationship, from: user1, to: user2, create_nodes: true)

# Find an existing relationship
Neo4j::Http::Client.find_relationship(relationship: relationship, from: user1, to: user2)

# Delete the relationship if it exists
Neo4j::Http::Client.delete_relationship(relationship: relationship, from: user1, to: user2)
```

Each of the methods exposed on `Neo4j::Http::Client` above are provided by instances of each of the following adapters:
* `Neo4j::Http::CypherClient` - provides an `execute_cypher` method which sends raw cypher commands to neo4j
* `Neo4j::Http::NodeClient` - provides a higher level API for upserting and deleting Nodes
* `Neo4j::Http::RelationshipClient` - provides a higher levle API for upserting and deleting Relationships

The Node and Relationship clients use the `CypherClient` under the hood.  Each of these provides simple access via a `default` class method, which uses the default `Neo4j::Http.config` for creating the connections. For example

`Neo4j::Http::NodeClient.default`

is equivalent to:

```
config = Neo4j::Http.config
cypher_client = Neo4j::Http::CypherClient.new(config)
node_client = Neo4j::Http::NodeClient.new(cypher_client)
```

to connect to a different Neo4j datbase, you can create a custom configuration like:
```
config = Neo4j::Http::Configuration.new({ datbase_name: 'test' })
cypher_client = Neo4j::Http::CypherClient.new(config)
node_client = Neo4j::Http::NodeClient.new(cypher_client)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/doximity/neo4j-http. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/doximity/neo4j-http/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Neo4j::Http project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](hhttps://github.com/doximity/neo4j-http/blob/master/CODE_OF_CONDUCT.mdttps://github.com/doximity/neo4j-http/blob/master/CODE_OF_CONDUCT.md).
