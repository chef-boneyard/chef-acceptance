require 'spec_helper'
require 'chef-acceptance/test_suite'

context 'ChefAcceptance::TestSuite' do
  let(:name) { 'supercalifragilisticexpialidocious' }
  let(:test_suite) { ChefAcceptance::TestSuite.new(name) }

  it 'does not exist' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)
      expect(test_suite.exist?).to be false
    end
  end

  it 'does exist' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)
      FileUtils.mkpath name
      expect(test_suite.exist?).to be true
    end
  end

  it 'raises existence error' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)
      expect { test_suite.exist! }.to raise_error
    end
  end
end
