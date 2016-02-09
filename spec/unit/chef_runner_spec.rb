require "spec_helper"
require "chef-acceptance/chef_runner"
require "chef-acceptance/test_suite"
require "chef-acceptance/acceptance_cookbook"

describe ChefAcceptance::ChefRunner do
  let(:acceptance_cookbook) { instance_double(ChefAcceptance::AcceptanceCookbook, root_dir: root_dir) }
  let(:test_suite) { instance_double(ChefAcceptance::TestSuite, name: "some_suite", acceptance_cookbook: acceptance_cookbook) }
  let(:recipe) { "provision" }
  let(:root_dir) { "/tmp" }
  let(:ccr) { ChefAcceptance::ChefRunner.new(test_suite, recipe) }
  let(:ccr_shellout) { instance_double(Mixlib::ShellOut) }

  it "initializes" do
    expect(ccr).to be_an_instance_of(ChefAcceptance::ChefRunner)
    expect(ccr.test_suite).to eq(test_suite)
    expect(ccr.acceptance_cookbook).to eq(acceptance_cookbook)
  end

  describe "run!" do
    before do
      allow(test_suite).to receive(:exist?).and_return(true)
      allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).and_return(true)
    end

    it "successfully runs the shellout" do
      # step into prepare_required_files
      expect(FileUtils).to receive(:rmtree).with("#{root_dir}/tmp")
      expect(FileUtils).to receive(:mkpath).with("#{root_dir}/tmp")
      expect(File).to receive(:write).with("#{root_dir}/tmp/dna.json", /suite-dir/)
      expect(FileUtils).to receive(:mkpath).with("#{root_dir}/tmp/.chef")
      expect(File).to receive(:write).with("#{root_dir}/tmp/.chef/config.rb", /cookbook_path/)

      expect(Mixlib::ShellOut).to receive(:new).with(
        [
          "chef-client -z",
          "-c /tmp/tmp/.chef/config.rb",
          "--force-formatter",
          "-j /tmp/tmp/dna.json",
          "-o acceptance-cookbook::provision",
          "--no-color",
        ].join(" "), cwd: root_dir, live_stream: instance_of(ChefAcceptance::Logger)
      ).and_return(ccr_shellout)
      expect(ccr_shellout).to receive(:run_command)
      expect(ccr_shellout).to receive(:execution_time).and_return(1)
      expect(ccr_shellout).to receive(:error!)

      expect { ccr.run! }.to_not raise_error
      expect(ccr.duration).to eq(1)
    end
  end

end
