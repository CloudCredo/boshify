require 'bundler'
require 'rubocop/rake_task'

require 'rspec/core/rake_task'

Bundler.setup
Bundler::GemHelper.install_tasks

namespace :spec do
  desc 'Run unit tests'
  RSpec::Core::RakeTask.new(:unit) do |r|
    r.pattern = 'spec/unit/**/*_spec.rb'
  end
  desc 'Run integration tests'
  RSpec::Core::RakeTask.new(:integration) do |r|
    r.pattern = 'spec/integration/**/*_spec.rb'
  end
end

desc 'Run RuboCop'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['bin/*']
  task.patterns = ['lib/**/*.rb']
  task.patterns = ['spec/**/*.rb']
end

task default: ['spec:unit', :rubocop]
