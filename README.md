# Neo4j::Http

The `Neo4j::Http` gem provides `a thin wrapper around the [Neo4j HTTP API](https://neo4j.com/docs/http-api/current/) (not the legacy REST api which was removed in 4.0). It works with Neo4j 3.5 through the latest release (at the time of this writing is 4.4)

## Why a new gem?
The available gems to interact with Neo4j are generally: out of date relying on legacy APIs removed in 4.x, require the use of JRuby, or out of date C bindings.

The goal of this gem is to provide a dependency free Ruby implementation that provides a simple wrapper to the [Neo4j HTTP API](https://neo4j.com/docs/http-api/current/)  to do most of what applications may need in order to leverage the power Neo4j provides.

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

The client is configured by default via a set of environment variables from [Neo4j::Http::Configuration](https://github.com/doximity/neo4j-http/blob/master/lib/neo4j/http/configuration.rb):

* `NEO4J_URL`  - The base URL to connect to Neo4j at - defaults to `"http://localhost:7474"`
* `NEO4J_USER` - The user name to use when authenticating to neo4j - defaults to `""`
* `NEO4J_PASSWORD` - The password of the user to be used for authentication - defaults to `""`
* `NEO4J_DATABASE` - The database name to be used when connecting.  By default this will be `nil`.
* `NEO4J_HTTP_USER_AGENT` - The user agent name provided in the request - defaults to `"Ruby Neo4j Http Client"`
* `NEO4J_REQUEST_TIMEOUT_IN_SECONDS` - The number of seconds for the http request to time out if provided - defaults to `nil`
* `ACCESS_MODE` - "WRITE", or "READ" for read only instances of Neo4j clients - defaults to `"WRITE"`

These configuration values can also be set during initalization, and take precedence over the environment variables:

```ruby
Neo4j::Http.configure do |config|
  config.uri = "http://localhost:7474"
  config.user = ""
  config.password = ""
  config.database_name = nil
  config.user_agent = "Ruby Neo4j Http Client"
  config.request_timeout_in_seconds = nil
  config.access_mode = "WRITE"
end
```

### Multiple databases

The HTTP API endpoints [follow the pattern](https://neo4j.com/docs/upgrade-migration-guide/current/migration/surface-changes/http-api/) `/db/<NEO4J_DATABASE>/tx`

To route to a different database, set a value for `NEO4J_DATABASE`. If no value is supplied, or this ENV is unset, the URI defaults to `/db/data/transaction/commit`

This can be used for testing by setting up a test environment only variable using a gem like [dotenv-rails](https://github.com/bkeepers/dotenv):

```
# .env.testing
NEO4J_DATABASE=test
```

All testing operations are now routed to the URI `/db/test/tx/commit`.

## Usage

The core interface can be directly accessed on `Neo4::Http::Client` -

### Execute arbitrary cypher commands
```ruby
Neo4j::Http::Client.execute_cypher('MATCH (n:User{id: $id}) return n LIMIT 25', id: 42)
```

### Upsert, find and delete nodes
```ruby
node = Neo4j::Http::Node.new(label: "User", uuid: SecureRandom.uuid)
Neo4j::Http::Client.upsert_node(node)
Neo4j::Http::Client.find_node_by(label: "User", uuid: node.uuid)
Neo4j::Http::Client.find_nodes_by(label: "User", name: "Testing")
Neo4j::Http::Client.delete_node(node)
```

### Create a new relationship, also creating the nodes if they do not exist
```ruby
user1 = Neo4j::Http::Node.new(label: "User", uuid: SecureRandom.uuid)
user2 = Neo4j::Http::Node.new(label: "User", uuid: SecureRandom.uuid)
relationship = Neo4j::Http::Relationship.new(label: "KNOWS")
Neo4j::Http::Client.upsert_relationship(relationship: relationship, from: user1, to: user2, create_nodes: true)
```

### Find an existing relationship
```ruby
Neo4j::Http::Client.find_relationship(relationship: relationship, from: user1, to: user2)
```

### Delete the relationship if it exists
```ruby
Neo4j::Http::Client.delete_relationship(relationship: relationship, from: user1, to: user2)
```

Each of the methods exposed on `Neo4j::Http::Client` above are provided by instances of each of the following adapters:
* `Neo4j::Http::CypherClient` - provides an `execute_cypher` method which sends raw cypher commands to neo4j
* `Neo4j::Http::NodeClient` - provides a higher level API for upserting and deleting Nodes
* `Neo4j::Http::RelationshipClient` - provides a higher level API for upserting and deleting Relationships

The Node and Relationship clients use the `CypherClient` under the hood.  Each of these provides simple access via a `default` class method, which uses the default `Neo4j::Http.config` for creating the connections. For example

`Neo4j::Http::NodeClient.default`

is equivalent to:

```
config = Neo4j::Http.config
cypher_client = Neo4j::Http::CypherClient.new(config)
node_client = Neo4j::Http::NodeClient.new(cypher_client)
```

to connect to a different Neo4j database, you can create a custom configuration like:
```
config = Neo4j::Http::Configuration.new({ database_name: 'test' })
cypher_client = Neo4j::Http::CypherClient.new(config)
node_client = Neo4j::Http::NodeClient.new(cypher_client)
```

## Batch operations

The `Neo4j::Http::Client.in_batch` will yield a batch client. It can be used like:

```ruby
Neo4j::Http::Client.in_batch do |tx|
  [
    tx.upsert_node(node),
    tx.upsert_node(node2),
    tx.upsert_relationship(relationship: relationship, from: from, to: to)
  ]
end
```

All of the commands need to chain off of the variable exposed by the block in order to
prepare the operations for the batch. These are not immediately invoked like their
single operation counterparts. The syntax and arguments are identical.

The array of statements will be passed into a batch client that will
prepare the statements and the parameters and issue a single
request to the Neo4j HTTP API. Note that the size of the batch is
determined by the caller's array length.

## Versioning

This project follows [semantic versioning](https://semver.org).

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To run specs, you'll need a running neo4j instance available at `localhost:7474`.  If you have Docker installed, this is easily done by using the provided [docker-file](https://github.com/doximity/neo4j-http/blob/master/docker-compose.yml) - simply run `docker-compose up` within the project directory, and once running, you can then, run `rake spec` to run the tests in another terminal.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, issue a pull request, and once merged with passing CI, the new gem version will be pushed automatically.

## Contributing

1. Fork it
2. Create your feature branch (`git switch -c my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
6. Sign the CLA if you haven't yet. See [CONTRIBUTING.md](https://github.com/doximity/neo4j-http/blob/master/CONTRIBUTING.md)

## License

The gem is licensed under an Apache 2 license. Contributors are required to sign an contributor license agreement. See [LICENSE.txt](https://github.com/doximity/neo4j-http/blob/master/LICENSE.txt) and [CONTRIBUTING.md](https://github.com/doximity/neo4j-http/blob/master/CONTRIBUTING.md) for more information.
