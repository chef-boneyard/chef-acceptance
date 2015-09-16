Gem::Specification.new do |s|
  s.name        = 'example'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = "This is an example!"
  s.description = "Much longer explanation of the example!"
  s.authors     = ["Ruby Coder"]
  s.email       = 'rubycoder@example.com'
  s.files       = ["lib/example.rb"]
  s.homepage    = 'https://rubygems.org/gems/example'

  s.add_dependency 'berks-monolith', '~> 0.1.1'
  s.add_dependency 'thor', '~> 0.19.1'

  s.require_path = 'lib'
   s.executables = ['chef-acceptance']
end
