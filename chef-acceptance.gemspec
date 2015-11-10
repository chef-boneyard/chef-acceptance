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
  s.executables   = %w(chef-acceptance)
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec)/}) }
  s.require_paths = ['lib']

  s.add_dependency 'thor', '~> 0.19'

  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'chef'
  s.add_development_dependency 'gem-release'
end
