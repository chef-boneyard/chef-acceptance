require "spec_helper"
require "chef-acceptance/application"

describe ChefAcceptance::Application do
  let(:app) { ChefAcceptance::Application.new }
  let(:formatter) { instance_double(ChefAcceptance::OutputFormatter) }
  let(:suite_name) { "my_suite" }
  let(:suite) { instance_double(ChefAcceptance::TestSuite, name: suite_name) }
  let(:command) { "some command" }
  before do
    allow(ChefAcceptance::OutputFormatter).to receive(:new).and_return(formatter)
  end

  describe "#initialize" do
    before do
      expect(ChefAcceptance::OutputFormatter).to receive(:new).and_return(formatter)
    end

    context "with defaults" do
      it "initializes" do
        expect(app.force_destroy).to be false
        expect(app.output_formatter).to be(formatter)
      end
    end

    context "with force_destroy set to true" do
      let(:app) { ChefAcceptance::Application.new("force_destroy" => true) }
      it "initializes with options" do
        expect(app.force_destroy).to be true
        expect(app.output_formatter).to be(formatter)
      end
    end
  end

  describe "#run_command" do
    let(:ccr) { instance_double(ChefAcceptance::ChefRunner) }

    context "when the command is force-destroy" do
      let(:command) { "force-destroy" }
      it "changes force-destroy to destroy" do
        expect(ChefAcceptance::ChefRunner).to receive(:new).with(suite, "destroy").and_return(ccr)
        expect(ccr).to receive(:run!)
        expect(ccr).to receive(:duration).and_return(0)
        expect(formatter).to receive(:add_row).with(suite: suite_name, command: command, duration: 0, error: false)
        expect { app.run_command(suite, command) }.to_not raise_error
      end
    end

    context "when the runner does not raise an error" do
      it "sends error: false to the formatter" do
        expect(ChefAcceptance::ChefRunner).to receive(:new).with(suite, command).and_return(ccr)
        expect(ccr).to receive(:run!)
        expect(ccr).to receive(:duration).and_return(0)
        expect(formatter).to receive(:add_row).with(suite: suite_name, command: command, duration: 0, error: false)
        expect { app.run_command(suite, command) }.to_not raise_error
      end
    end

    context "when the runner raises an error" do
      it "sends error: false to the formatter" do
        expect(ChefAcceptance::ChefRunner).to receive(:new).with(suite, command).and_return(ccr)
        expect(ccr).to receive(:run!).and_raise("some error")
        expect(ccr).to receive(:duration).and_return(0)
        expect(formatter).to receive(:add_row).with(suite: suite_name, command: command, duration: 0, error: true)
        expect { app.run_command(suite, command) }.to raise_error("some error")
      end
    end
  end

  describe "#run_suite" do
    before do
      expect(ChefAcceptance::TestSuite).to receive(:new).with(suite).and_return(suite)
      allow(suite).to receive(:exist?).and_return(true)
      allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).and_return(true)
    end

    context "when suite does not exist" do
      it "fails" do
        expect(suite).to receive(:exist?).and_return(false)
        expect { app.run_suite(suite, command) }.to raise_error(/in the current working directory/)
      end
    end

    context "when chef executable does not exist" do
      it "fails" do
        allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).and_return(false)
        expect { app.run_suite(suite, command) }.to raise_error(/Could not find chef-client in/)
      end
    end

    context "when command is 'test'" do
      let(:command) {"test"}
      context "when provisioning fails" do
        context "with force_destroy set to true" do
          let(:app) { ChefAcceptance::Application.new("force_destroy" => true) }
          it "runs a destroy after an error" do
            expect(app).to receive(:run_command).with(suite, "provision").and_raise("some error")
            expect(app).to receive(:run_command).with(suite, "force-destroy")
            expect { app.run_suite(suite, "test") }.to raise_error("some error")
          end
        end

        it "raises the provisioning error" do
          expect(app).to receive(:run_command).with(suite, "provision").and_raise("some error")
          expect { app.run_suite(suite, "test") }.to raise_error("some error")
        end
      end

      it "runs successfully" do
        expect(app).to receive(:run_command).with(suite, "provision")
        expect(app).to receive(:run_command).with(suite, "verify")
        expect(app).to receive(:run_command).with(suite, "destroy")
        expect { app.run_suite(suite, "test") }.to_not raise_error
      end
    end
  end

  describe "#run" do
    context "when run_suite does not raise an error" do
      it "adds error: false to the output formatter" do
        expect(app).to receive(:run_suite).with(suite, command)
        expect(formatter).to receive(:add_row).with(suite: "", command: "Total", duration: be_a(Numeric), error: false)
        expect(formatter).to receive(:generate_output)
        stdout = capture(:stdout) do
          expect { app.run(suite, command) }.to_not raise_error
        end
        expect(stdout).to match(/chef-acceptance run succeeded/)
      end
    end

    context "when run_suite raises an AcceptanceError" do
      it "does not call the output formatter" do
        expect(app).to receive(:run_suite).with(suite, command).and_raise(ChefAcceptance::AcceptanceError)
        stdout = capture(:stdout) do
          expect { app.run(suite, command) }.to raise_error(SystemExit)
        end
        expect(stdout).to match(/ChefAcceptance::AcceptanceError/)
      end
    end

    context "when run_suite raises an RuntimeError" do
      it "adds error: true to the output formatter" do
        expect(app).to receive(:run_suite).with(suite, command).and_raise("some error")
        expect(formatter).to receive(:add_row).with(suite: "", command: "Total", duration: be_a(Numeric), error: true)
        expect(formatter).to receive(:generate_output)
        stdout = capture(:stdout) do
          expect { app.run(suite, command) }.to raise_error(SystemExit)
        end
        expect(stdout).to match(/chef-acceptance run failed/)
      end
    end
  end

end
