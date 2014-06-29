require 'bundler'
require 'rubocop/rake_task'

require 'rspec/core/rake_task'

Bundler.setup
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)

desc 'Run RuboCop'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['bin/*']
  task.patterns = ['lib/**/*.rb']
end

task default: [:spec, :rubocop]
