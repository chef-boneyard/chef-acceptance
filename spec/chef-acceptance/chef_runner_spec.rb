require 'spec_helper'
require 'chef-acceptance/chef_runner'
require 'chef-acceptance/test_suite'
require 'chef-acceptance/acceptance_cookbook'

describe ChefAcceptance::ChefRunner do
  let(:test_suite) { instance_double(ChefAcceptance::TestSuite, name: "some_suite", acceptance_cookbook: acceptance_cookbook) }
  let(:root_dir) { "some path" }
  let(:acceptance_cookbook) { instance_double(ChefAcceptance::AcceptanceCookbook, root_dir: root_dir) }
  let(:runner) { ChefAcceptance::ChefRunner.new(test_suite) }
  let(:recipe) { "provision" }
  let(:shellout_builder) { instance_double(ChefAcceptance::ShelloutBuilder) }
  let(:chef_shellout) { instance_double(Mixlib::ShellOut) }

  it "initializes" do
    expect(runner).to be_an_instance_of(ChefAcceptance::ChefRunner)
    expect(runner.shellout_builder).to be_an_instance_of(ChefAcceptance::ShelloutBuilder)
    expect(runner.shellout_builder.cwd).to eq root_dir
  end

  describe "run!" do
    before do
      allow(runner).to receive(:shellout_builder).and_return(shellout_builder)
      allow(test_suite).to receive(:exist?).and_return(true)
      allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).and_return(true)
    end

    context "when test_suite does not exist" do
      it "fails" do
        expect(test_suite).to receive(:exist?).and_return(false)
        expect { runner.run!(recipe) }.to raise_error(/in the current working directory/)
      end
    end

    context "when chef-client executable is not installed" do
      it "fails" do
        expect(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).and_return(false)
        expect { runner.run!(recipe) }.to raise_error(/Could not find chef-client/)
      end
    end

    it "successfully runs the shellout" do
      # step into prepare_required_files
      expect(FileUtils).to receive(:rmtree).with("#{root_dir}/tmp")
      expect(FileUtils).to receive(:mkpath).with("#{root_dir}/tmp")
      expect(File).to receive(:write).with("#{root_dir}/tmp/dna.json", /suite-dir/)
      expect(FileUtils).to receive(:mkpath).with("#{root_dir}/tmp/.chef")
      expect(File).to receive(:write).with("#{root_dir}/tmp/.chef/config.rb", /cookbook_path/)

      expect(shellout_builder).to receive(:with_chef_config_file).with("#{root_dir}/tmp/.chef/config.rb")
      expect(shellout_builder).to receive(:with_dna_json_file).with("#{root_dir}/tmp/dna.json")
      expect(shellout_builder).to receive(:with_recipe).with("acceptance-cookbook::#{recipe}")
      expect(shellout_builder).to receive(:build).and_return(chef_shellout)
      expect(chef_shellout).to receive(:run_command)
      expect(chef_shellout).to receive(:error!)

      expect { runner.run!(recipe) }.to_not raise_error
    end
  end

end
