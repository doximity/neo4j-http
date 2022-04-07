require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"


RSpec::Core::RakeTask.new("spec")

task :default => :spec

namespace :ci do
  task :specs => :spec
  task :standardrb => :standardrb
end
