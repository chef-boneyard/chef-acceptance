require 'spec_helper'
require 'chef-acceptance/test_suite'

context 'ChefAcceptance::TestSuite' do
  let(:name) { 'supercalifragilisticexpialidocious' }
  let(:test_suite) { ChefAcceptance::TestSuite.new(name) }

  it 'returns acceptance_cookbook_dir' do
    expect(test_suite.acceptance_cookbook_dir).to eq "#{name}/.acceptance/acceptance-cookbook"
  end

  it 'returns recipes_dir' do
    expect(test_suite.recipes_dir).to eq "#{name}/.acceptance/acceptance-cookbook/recipes"
  end

  it 'returns chef_dir' do
    expect(test_suite.chef_dir).to eq "#{name}/.acceptance/acceptance-cookbook/.chef"
  end

  it 'returns chef_config_file' do
    expect(test_suite.chef_config_file).to eq "#{name}/.acceptance/acceptance-cookbook/.chef/config.rb"
  end

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
