require "spec_helper"
require "chef-acceptance/chef_runner"
require "chef-acceptance/test_suite"

context ChefAcceptance::ChefRunner do
  it "calls run" do
    Dir.mktmpdir do |dir|
      ChefAcceptance::AcceptanceCookbook.new(File.join(dir, "foo", ".acceptance")).generate
      Dir.chdir dir
      test_suite = ChefAcceptance::TestSuite.new("foo")
      runner = ChefAcceptance::ChefRunner.new(test_suite, "provision")

      expect(capture(:stdout) { runner.run! }).to match(/Running 'provision' recipe from the acceptance-cookbook in directory '.*foo'/)
    end
  end

  it "calls run and picks up shared cookbooks" do
    Dir.mktmpdir do |dir|
      ChefAcceptance::AcceptanceCookbook.new(File.join(dir, "foo", ".acceptance")).generate
      # Create an empty testme cookbook in .shared/testme
      Dir.mkdir File.join(dir, ".shared")
      Dir.mkdir File.join(dir, ".shared", "testme")
      IO.write(File.join(dir, ".shared", "testme", "metadata.rb"), <<-EOM)
        name "testme"
      EOM
      # Depend on the testme cookbook in the acceptance-cookbook
      IO.write(File.join(dir, "foo", ".acceptance", "acceptance-cookbook", "metadata.rb"), <<-EOM)
        name "acceptance-cookbook"
        depends "testme"
      EOM
      Dir.chdir dir
      test_suite = ChefAcceptance::TestSuite.new("foo")
      runner = ChefAcceptance::ChefRunner.new(test_suite, "provision")

      expect(capture(:stdout) { runner.run! }).to match(/Running 'provision' recipe from the acceptance-cookbook in directory '.*foo'/)
    end
  end
end
