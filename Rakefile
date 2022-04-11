require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new("spec")

task default: :spec

namespace :ci do
  desc "Run specs in CI"
  task specs: :spec

  desc "Run standard RB in CI"
  task standardrb: :standard
end
