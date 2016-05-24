require "spec_helper"
require "chef-acceptance/cli"

context "ChefAcceptance::Cli" do
  before do
    Dir.chdir(ACCEPTANCE_TEST_DIRECTORY)
    FileUtils.rm_rf(acceptance_data_path)
  end

  after do
    FileUtils.rm_rf(acceptance_data_path)
  end

  let(:failure_expected) { false }
  let(:acceptance_data_path) { File.join(ACCEPTANCE_TEST_DIRECTORY, ".acceptance_data") }
  let(:acceptance_log) {
    File.read(File.join(acceptance_data_path, "logs", "acceptance.log"))
  }

  def suite_log_for(suite_name, command)
    File.read(File.join(acceptance_data_path, "logs", suite_name, "#{command}.log"))
  end

  def run_acceptance
    capture(:stdout) do
      begin
        ChefAcceptance::Cli.start(options)
      rescue SystemExit
        expect(failure_expected).to be(true)
      end
    end
  end

  it "exits with non-zero error code" do
    expect(ChefAcceptance::Cli.exit_on_failure?).to be(true)
  end

  context "with invalid command" do
    let(:options) { [ "non-existing"] }
    let(:failure_expected) { true }

    it "exits non-zero" do
      # Setting :failure_expected is going to check for SystemExit
      # which means Cli will exit with non-zero exit code
      run_acceptance
    end
  end

  context "with invalid option" do
    let(:options) { [ "test", "--non-existing" ] }
    let(:failure_expected) { true }

    it "exits non-zero" do
      # Setting :failure_expected is going to check for SystemExit
      # which means Cli will exit with non-zero exit code
      run_acceptance
    end
  end

  context "for an invalid test suite" do
    let(:options) { %w{provision invalid} }
    let(:failure_expected) { true }

    it "CLI gives the right error" do
      expect(run_acceptance).to match(/No matching test suites found using regex 'invalid'/)
    end
  end

  context "for a valid test suite" do
    %w{ provision verify destroy }.each do |command|
      context "with #{command} command" do
        let(:options) { [ command, "test-suite" ] }

        it "runs successfully" do
          stdout = run_acceptance
          expect(stdout).to match(/the #{command} recipe/)
          expect(suite_log_for("test-suite", command)).to match(/the #{command} recipe/)
          expect_in_acceptance_logs("test-suite", command, false, stdout, acceptance_log)
        end
      end
    end

    context "with custom data_path and provision command" do
      let(:acceptance_data_path) { Dir.mktmpdir }
      let(:options) { [ "provision", "test-suite", "--data-path=#{acceptance_data_path}" ] }

      it "runs successfully" do
        stdout = run_acceptance
        expect(stdout).to match(/the provision recipe/)
        expect(suite_log_for("test-suite", "provision")).to match(/the provision recipe/)
        expect_in_acceptance_logs("test-suite", "provision", false, stdout, acceptance_log)
      end
    end

    context "with test command" do
      let(:options) { %w{test test-suite} }

      it "runs successfully" do
        stdout = run_acceptance
        %w{provision verify destroy}.each do |command|
          suite_log = suite_log_for("test-suite", command)
          expect(stdout).to match(/the #{command} recipe/)
          expect(suite_log).to match(/the #{command} recipe/)
          expect(suite_log).to match(/TEST-SUITE::#{command.upcase}::/)
          expect_in_acceptance_logs("test-suite", command, false, stdout, acceptance_log)
        end
      end
    end

    context "with test --force-destroy" do
      let(:options) { %w{test test-suite --force-destroy} }

      it "runs successfully" do
        stdout = run_acceptance
        %w{provision verify destroy}.each do |command|
          expect(stdout).to match(/the #{command} recipe/)
          expect(suite_log_for("test-suite", command)).to match(/the #{command} recipe/)
          expect_in_acceptance_logs("test-suite", command, false, stdout, acceptance_log)
        end
        expect(stdout).not_to match(/force-destroy/)
        expect(acceptance_log).not_to match(/force-destroy/)
      end
    end
  end

  context "for a failing verify phase in the suite" do
    context "with verify command" do
      let(:options) { %w{verify error-suite} }
      let(:failure_expected) { true }

      it "fails" do
        stdout = run_acceptance
        suite_log = suite_log_for("error-suite", "verify")
        expect(stdout).to match(/recipes\/verify.rb:1: syntax error/)
        expect(suite_log).to match(/recipes\/verify.rb:1: syntax error/)
        expect_in_acceptance_logs("error-suite", "verify", true, stdout, acceptance_log)
        expect(stdout).not_to match(/force-destroy/)
        expect(suite_log).not_to match(/force-destroy/)
        expect(acceptance_log).not_to match(/force-destroy/)

      end
    end

    context "with test command" do
      let(:options) { %w{test error-suite} }
      let(:failure_expected) { true }

      it "fails" do
        stdout = run_acceptance
        expect(stdout).to match(/provision phase/)
        expect(stdout).to match(/recipes\/verify.rb:1: syntax error/)
        expect(suite_log_for("error-suite", "provision")).to match(/provision phase/)
        expect(suite_log_for("error-suite", "verify")).to match(/recipes\/verify.rb:1: syntax error/)
        expect_in_acceptance_logs("error-suite", "provision", false, stdout, acceptance_log)
        expect_in_acceptance_logs("error-suite", "verify", true, stdout, acceptance_log)
        expect(stdout).not_to match(/force-destroy/)
        expect(acceptance_log).not_to match(/force-destroy/)
      end
    end

    context "with test --force-destroy" do
      let(:options) { %w{test error-suite --force-destroy} }
      let(:failure_expected) { true }

      it "fails" do
        stdout = run_acceptance
        expect(stdout).to match(/provision phase/)
        expect(stdout).to match(/recipes\/verify.rb:1: syntax error/)
        expect(suite_log_for("error-suite", "provision")).to match(/provision phase/)
        expect(suite_log_for("error-suite", "verify")).to match(/recipes\/verify.rb:1: syntax error/)
        expect_in_acceptance_logs("error-suite", "provision", false, stdout, acceptance_log)
        expect_in_acceptance_logs("error-suite", "verify", true, stdout, acceptance_log)
        expect_in_acceptance_logs("error-suite", "force-destroy", false, stdout, acceptance_log)
      end
    end
  end

  context "with a regex" do
    let(:options) { %w{test -suite} }
    let(:failure_expected) { true }

    it "fails running both of the suites" do
      stdout = run_acceptance
      expect(stdout).to match(/provision phase/)
      expect(stdout).to match(/recipes\/verify.rb:1: syntax error/)
      expect(suite_log_for("error-suite", "provision")).to match(/provision phase/)
      expect(suite_log_for("error-suite", "verify")).to match(/recipes\/verify.rb:1: syntax error/)
      expect(suite_log_for("test-suite", "provision")).to match(/the provision recipe/)
      expect(suite_log_for("test-suite", "verify")).to match(/the verify recipe/)
      expect(suite_log_for("test-suite", "destroy")).to match(/the destroy recipe/)
      expect_in_acceptance_logs("error-suite", "provision", false, stdout, acceptance_log)
      expect_in_acceptance_logs("error-suite", "verify", true, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "provision", false, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "verify", false, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "destroy", false, stdout, acceptance_log)
    end
  end

  context "by default" do
    let(:options) { %w{test} }
    let(:failure_expected) { true }

    it "fails running both of the suites" do
      stdout = run_acceptance
      expect(stdout).to match(/provision phase/)
      expect(stdout).to match(/recipes\/verify.rb:1: syntax error/)
      expect(suite_log_for("error-suite", "provision")).to match(/provision phase/)
      expect(suite_log_for("error-suite", "verify")).to match(/recipes\/verify.rb:1: syntax error/)
      expect(suite_log_for("test-suite", "provision")).to match(/the provision recipe/)
      expect(suite_log_for("test-suite", "verify")).to match(/the verify recipe/)
      expect(suite_log_for("test-suite", "destroy")).to match(/the destroy recipe/)
      expect_in_acceptance_logs("error-suite", "provision", false, stdout, acceptance_log)
      expect_in_acceptance_logs("error-suite", "verify", true, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "provision", false, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "verify", false, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "destroy", false, stdout, acceptance_log)
    end
  end

  context "--no-audit-mode" do
    let(:options) { %w{test test-suite --no-audit-mode} }

    it "sets audit_mode to disabled" do
      stdout = run_acceptance
      config_rb = File.join(ACCEPTANCE_TEST_DIRECTORY, ".acceptance_data", "chef", "test-suite", "provision", ".chef", "config.rb")
      expect(File.read(config_rb)).to match "audit_mode :disabled"
    end
  end
end
