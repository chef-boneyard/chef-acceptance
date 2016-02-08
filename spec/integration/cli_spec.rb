require "spec_helper"
require "chef-acceptance/cli"

context "ChefAcceptance::Cli" do
  before do
    Dir.chdir(ACCEPTANCE_TEST_DIRECTORY)
    FileUtils.rm_rf(File.join(ACCEPTANCE_TEST_DIRECTORY, ".acceptance_logs"))
  end

  after do
    FileUtils.rm_rf(File.join(ACCEPTANCE_TEST_DIRECTORY, ".acceptance_logs"))
  end

  let(:failure_expected) { false }

  let(:acceptance_log) {
    File.read(File.join(ACCEPTANCE_TEST_DIRECTORY, ".acceptance_logs", "acceptance.log"))
  }

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
          expect_in_acceptance_logs("test-suite", command, false, stdout, acceptance_log)
        end
      end
    end

    context "with test command" do
      let(:options) { %w{test test-suite} }

      it "runs successfully" do
        stdout = run_acceptance
        %w{provision verify destroy}.each do |command|
          expect(stdout).to match(/the #{command} recipe/)
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
        expect(stdout).to match(/recipes\/verify.rb:1: syntax error/)
        expect_in_acceptance_logs("error-suite", "verify", true, stdout, acceptance_log)
        expect(stdout).not_to match(/force-destroy/)
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
      expect_in_acceptance_logs("error-suite", "provision", false, stdout, acceptance_log)
      expect_in_acceptance_logs("error-suite", "verify", true, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "provision", false, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "verify", false, stdout, acceptance_log)
      expect_in_acceptance_logs("test-suite", "destroy", false, stdout, acceptance_log)
    end
  end
end
