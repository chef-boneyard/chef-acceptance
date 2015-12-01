require 'spec_helper'
require 'chef-acceptance/chef_runner'
require 'chef-acceptance/test_suite'

context 'ChefAcceptance::ChefRunner' do
  it 'calls run' do
    Dir.mktmpdir do |dir|
      ChefAcceptance::AcceptanceCookbook.new(File.join(dir, 'foo', '.acceptance')).generate
      Dir.chdir dir
      test_suite = ChefAcceptance::TestSuite.new('foo')
      runner = ChefAcceptance::ChefRunner.new(test_suite, run_recipes: ['provision'])

      expect(capture(:stdout) { runner.run }).to match(/Running 'provision' recipe from the acceptance-cookbook in directory '.*foo'/)

      Dir.chdir File.join('foo', '.acceptance', 'acceptance-cookbook')
      expect(File.exist?(File.join('tmp', '.chef', 'config.rb'))).to be true
      expect(File.exist?(File.join('tmp', 'dna.json'))).to be true
    end
  end
end
