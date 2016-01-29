require "spec_helper"
require "chef-acceptance/cli"

context "ChefAcceptance::Cli" do
  before(:all) do
    Dir.chdir(ACCEPTANCE_TEST_DIRECTORY)
  end

  let(:failure_expected) { false }
  let(:duration_regex) { /\d{2}:\d{2}:\d{2}/ }

  def run_acceptance
    capture(:stdout) do
      begin
        ChefAcceptance::Cli.start(options)
      rescue SystemExit
        expect(failure_expected).to be(true)
      end
    end
  end

  context "for an invalid test suite" do
    let(:options) { %w{provision invalid} }
    let(:failure_expected) { true }

    it "CLI gives the right error" do
      expect(run_acceptance).to match(/Could not find test suite 'invalid'/)
    end
  end


  context "for a valid test suite" do
    %w{ provision verify destroy }.each do |command|
      context "with #{command} command" do
        let(:options) { [ command, "test-suite" ] }

        it "runs successfully" do
          output = run_acceptance
          expect(output).to match(/the #{command} recipe/)
          expect(output).to match(/\| test-suite \| #{command}\s+\| #{duration_regex} \| N     \|/)
        end
      end
    end

    context "with test command" do
      let(:options) { %w{test test-suite} }

      it "runs successfully" do
        output = run_acceptance
        expect(output).to match(/the provision recipe/)
        expect(output).to match(/the verify recipe/)
        expect(output).to match(/the destroy recipe/)
        expect(output).to match(/\| test-suite \| provision \| #{duration_regex} \| N     \|/)
        expect(output).to match(/\| test-suite \| verify    \| #{duration_regex} \| N     \|/)
        expect(output).to match(/\| test-suite \| destroy   \| #{duration_regex} \| N     \|/)
      end
    end

    context "with test --force-destroy" do
      let(:options) { %w{test test-suite --force-destroy} }

      it "runs successfully" do
        output = run_acceptance
        expect(output).to match(/the provision recipe/)
        expect(output).to match(/the verify recipe/)
        expect(output).to match(/the destroy recipe/)
        expect(output).to match(/\| test-suite \| provision \| #{duration_regex} \| N     \|/)
        expect(output).to match(/\| test-suite \| verify    \| #{duration_regex} \| N     \|/)
        expect(output).to match(/\| test-suite \| destroy   \| #{duration_regex} \| N     \|/)
        expect(output).not_to match(/force-destroy/)
      end
    end
  end


  context "for a failing verify phase in the suite" do
    context "with verify command" do
      let(:options) { %w{verify error-suite} }
      let(:failure_expected) { true }

      it "fails" do
        output = run_acceptance
        expect(output).to match(/recipes\/verify.rb:1: syntax error/)
        expect(output).to match(/\| error-suite \| verify  \| #{duration_regex} \| Y     \|/)
        expect(output).not_to match(/force-destroy/)
      end
    end

    context "with test command" do
      let(:options) { %w{test error-suite} }
      let(:failure_expected) { true }

      it "fails" do
        output = run_acceptance
        expect(output).to match(/provision phase/)
        expect(output).to match(/recipes\/verify.rb:1: syntax error/)
        expect(output).to match(/\| error-suite \| provision \| #{duration_regex} \| N     \|/)
        expect(output).to match(/\| error-suite \| verify    \| #{duration_regex} \| Y     \|/)
        expect(output).not_to match(/force-destroy/)
      end
    end

    context "with test --force-destroy" do
      let(:options) { %w{test error-suite --force-destroy} }
      let(:failure_expected) { true }

      it "fails" do
        output = run_acceptance
        expect(output).to match(/provision phase/)
        expect(output).to match(/recipes\/verify.rb:1: syntax error/)
        expect(output).to match(/\| error-suite \| provision     \| #{duration_regex} \| N     \|/)
        expect(output).to match(/\| error-suite \| verify        \| #{duration_regex} \| Y     \|/)
        expect(output).to match(/\| error-suite \| force-destroy \| #{duration_regex} \| N     \|/)
      end
    end
  end

end
