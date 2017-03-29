require "bundler"
require "bundler/gem_tasks"
require "rubocop/rake_task"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  puts "rspec is not available."
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "chefstyle is not available."
end

task default: [ :spec, :style ]
