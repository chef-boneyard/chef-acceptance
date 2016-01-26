require "spec_helper"
require "chef-acceptance/application"

describe ChefAcceptance::Application do
  let(:app) { ChefAcceptance::Application.new }

  describe "#initialize" do

    context "with defaults" do
      it "initializes" do
        expect(app.force_destroy).to be false
      end
    end

    context "with force_destroy set to true" do
      let(:app) { ChefAcceptance::Application.new(force_destroy: true) }
      it "initializes with options" do
        expect(app.force_destroy).to be true
      end
    end
  end

  describe "#run_command" do
    let(:ccr) { instance_double(ChefAcceptance::ChefRunner) }
    it "runs" do
      expect(ChefAcceptance::ChefRunner).to receive(:new).with("a", "b").and_return(ccr)
      expect(ccr).to receive(:run!)
      expect { app.run_command("a", "b") }.to_not raise_error
    end
  end

  describe "#run" do
    let(:suite) { "my_suite" }
    let(:command) { "provision" }
    let(:test_suite) { instance_double(ChefAcceptance::TestSuite, name: suite) }
    before do
      expect(ChefAcceptance::TestSuite).to receive(:new).with(suite).and_return(test_suite)
      allow(test_suite).to receive(:exist?).and_return(true)
      allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).and_return(true)
    end

    context "when test_suite does not exist" do
      it "fails" do
        expect(test_suite).to receive(:exist?).and_return(false)
        expect { app.run(suite, command) }.to raise_error(/in the current working directory/)
      end
    end

    context "when chef executable does not exist" do
      it "fails" do
        allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).and_return(false)
        expect { app.run(suite, command) }.to raise_error(/Could not find chef-client in/)
      end
    end

    context "when command is 'test'" do
      context "when provisioning fails" do
        context "with force_destroy set to true" do
          let(:app) { ChefAcceptance::Application.new(force_destroy: true) }
          it "runs a destroy after an error" do
            expect(app).to receive(:run_command).with(test_suite, "provision").and_raise("some error")
            expect(app).to receive(:run_command).with(test_suite, "destroy")
            expect { app.run(suite, "test") }.to raise_error("some error")
          end
        end

        it "raises the provisioning error" do
          expect(app).to receive(:run_command).with(test_suite, "provision").and_raise("some error")
          expect { app.run(suite, "test") }.to raise_error("some error")
        end
      end

      it "runs successfully" do
        expect(app).to receive(:run_command).with(test_suite, "provision")
        expect(app).to receive(:run_command).with(test_suite, "verify")
        expect(app).to receive(:run_command).with(test_suite, "destroy")
        expect { app.run(suite, "test") }.to_not raise_error
      end
    end
  end
end
