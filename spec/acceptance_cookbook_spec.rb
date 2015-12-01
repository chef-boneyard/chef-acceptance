require 'spec_helper'
require 'chef-acceptance/acceptance_cookbook'

context 'ChefAcceptance::AcceptanceCookbook' do
  let(:acceptance_cookbook) { ChefAcceptance::AcceptanceCookbook }

  it 'generates a cookbook' do
    Dir.mktmpdir do |dir|
      acceptance_cookbook.new(dir).generate

      %w(metadata.rb .gitignore).each do |file|
        path = File.join(dir, 'acceptance-cookbook', file)
        expect(File.exist?(path)).to be true
      end

      ChefAcceptance::AcceptanceCookbook::CORE_ACCEPTANCE_RECIPES.each do |recipe|
        path = File.join(dir, 'acceptance-cookbook', 'recipes', "#{recipe}.rb")
        expect(File.exist?(path)).to be true
      end
    end
  end
end
