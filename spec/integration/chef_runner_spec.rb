require "spec_helper"
require "chef-acceptance/chef_runner"
require "chef-acceptance/test_suite"

context ChefAcceptance::ChefRunner do
  let(:test_suite) { ChefAcceptance::TestSuite.new("foo") }
  let(:options) { { "audit_mode" => false } }
  let(:options_instance) { ChefAcceptance::Options.new(options) }
  let(:runner) { ChefAcceptance::ChefRunner.new(test_suite, "provision", options_instance) }

  def run
    capture(:stdout) do
      runner.run!
      runner.send_log_to_stdout
    end
  end

  it "calls run" do
    Dir.mktmpdir do |dir|
      ChefAcceptance::AcceptanceCookbook.new(File.join(dir, "foo", ".acceptance")).generate
      Dir.chdir dir

      expect(run).to match(/Running 'provision' recipe from the acceptance-cookbook in directory '.*foo'/)
    end
  end

  it "calls run and picks up shared cookbooks" do
    Dir.mktmpdir do |dir|
      ChefAcceptance::AcceptanceCookbook.new(File.join(dir, "foo", ".acceptance")).generate
      # Create an empty testme cookbook in .shared/testme
      Dir.mkdir File.join(dir, ".shared")
      Dir.mkdir File.join(dir, ".shared", "testme")
      IO.write(File.join(dir, ".shared", "testme", "metadata.rb"), <<-EOM
          name "testme"
        EOM
      )
      # Depend on the testme cookbook in the acceptance-cookbook
      IO.write(File.join(dir, "foo", ".acceptance", "acceptance-cookbook", "metadata.rb"), <<-EOM)
        name "acceptance-cookbook"
        depends "testme"
      EOM
      Dir.chdir dir

      expect(run).to match(/Running 'provision' recipe from the acceptance-cookbook in directory '.*foo'/)
    end
  end

  context "with a ridiculously short timeout setting" do
    let(:options) { { "timeout" => 1 } }

    it "times out" do
      Dir.mktmpdir do |dir|
        ChefAcceptance::AcceptanceCookbook.new(File.join(dir, "foo", ".acceptance")).generate
        Dir.chdir dir
        expect { runner.run! }.to raise_error(Mixlib::ShellOut::CommandTimeout)
      end
    end
  end
end
