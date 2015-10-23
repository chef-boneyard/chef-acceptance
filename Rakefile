require 'bundler'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: :test

desc 'run specs'
RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = 'spec/**/*_spec.rb'
end

desc 'Run rubocop'
RuboCop::RakeTask.new do |task|
  task.options << '--display-cop-names'
end

desc 'Run all tests'
task test: [:rubocop, :spec]
