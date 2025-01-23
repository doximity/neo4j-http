require_relative "lib/neo4j/http/version"

Gem::Specification.new do |spec|
  spec.name = "neo4j-http"
  spec.version = Neo4j::Http::VERSION
  spec.authors = ["Ryan Stawarz"]
  spec.email = ["ryan@stawarz.com"]

  spec.summary = "A simple HTTP client for Neo4j"
  spec.description = "Allows exeucting arbitrary cypher commands and simplifies creating nodes and relationships"
  spec.homepage = "https://github.com/doximity/neo4j-http"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/doximity/neo4j-http"
  spec.metadata["changelog_uri"] = "https://github.com/doximity/neo4j-http/blob/master/CHANGELOG.md"

  spec.files = Dir["{lib}/**/*", "Rakefile", "README.md"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 5.2"
  spec.add_runtime_dependency "faraday", "~> 2.0"
  spec.add_runtime_dependency "faraday-httpclient"
  spec.add_runtime_dependency "faraday-retry"
  spec.add_runtime_dependency "pry"
end
