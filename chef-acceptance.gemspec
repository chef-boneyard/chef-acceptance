Gem::Specification.new do |s|
  s.name        = 'chef-acceptance'
  s.version     = '0.1.0'
  s.summary     = "Chef Acceptance Framework"
  s.description = "Framework for executing embedded Chef acceptance tests"
  s.authors     = ["Patrick Wright"]
  s.email       = 'patrick@chef.io'
  s.executables = %w[chef-acceptance]
  s.add_dependency 'thor', '~> 0.19.1'
end
