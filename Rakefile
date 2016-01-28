require 'bundler'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: :test

desc 'run unit tests'
RSpec::Core::RakeTask.new(:unit) do |task|
  task.pattern = 'spec/chef-acceptance/*_spec.rb'
end

desc 'run integration tests'
RSpec::Core::RakeTask.new(:integration) do |task|
  task.pattern = 'spec/integration/*_spec.rb'
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "chefstyle/rubocop is not available.  gem install chefstyle to do style checking."
end

desc 'Run all tests'
task test: [:style, :unit, :integration]
