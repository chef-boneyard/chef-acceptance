require "spec_helper"
require "chef-acceptance/test_suite"
require "chef-acceptance/acceptance_cookbook"

context "ChefAcceptance::TestSuite" do
  let(:name) { "supercalifragilisticexpialidocious" }
  let(:test_suite) { ChefAcceptance::TestSuite.new(name) }

  before do
    ensure_project_root
  end

  it "does not exist" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)
      expect(test_suite.exist?).to be false
    end
  end

  it "does exist" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)
      FileUtils.mkpath name
      expect(test_suite.exist?).to be true
    end
  end

  context "with provided acceptance cookbook" do
    let(:cookbook) { ChefAcceptance::AcceptanceCookbook.new(Dir.pwd) }
    let(:test_suite) { ChefAcceptance::TestSuite.new(name, acceptance_cookbook: cookbook) }

    it "initializes with provided cookbook" do
      expect(test_suite.acceptance_cookbook).to be(cookbook)
    end
  end
end
