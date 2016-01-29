$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'chef-acceptance/version'

Gem::Specification.new do |s|
  s.name          = 'chef-acceptance'
  s.version       = ChefAcceptance::VERSION
  s.summary       = 'Chef Acceptance Framework'
  s.description   = 'Framework for executing embedded Chef acceptance tests'
  s.homepage      = 'http://github.com/chef/chef-acceptance'
  s.authors       = ['Patrick Wright']
  s.email         = 'patrick@chef.io'
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec)/}) }
  s.require_paths = ['lib']
  s.bindir        = "bin"
  s.executables   = %w{ chef-acceptance }

  s.add_dependency 'thor', '~> 0.19'
  s.add_dependency "mixlib-shellout", "~> 2.0"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'chef'
  s.add_development_dependency 'gem-release'
  s.add_development_dependency 'chefstyle'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'pry-stack_explorer'
end
