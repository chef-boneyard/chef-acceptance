require "spec_helper"
require "chef-acceptance/application"

describe ChefAcceptance::Application do
  let(:app) { ChefAcceptance::Application.new(app_options) }
  let(:app_options) { {} }
  let(:failure_expected) { false }
  let(:suites) { [] }
  let(:acceptance_log) {
    File.read(File.join(@acceptance_dir, ".acceptance_data", "logs", "acceptance.log"))
  }

  before do
    @acceptance_dir = Dir.mktmpdir
    Dir.chdir @acceptance_dir
    suites.each do |suite|
      Dir.mkdir File.join(@acceptance_dir, suite)
    end
  end

  after do
    FileUtils.rmdir @acceptance_dir if @acceptance_dir
  end

  # this function captures the stdout and returns it.
  def application_run(suite_regex, command)
    capture(:stdout) do
      begin
        app.run(suite_regex, command)
      rescue SystemExit
        expect(failure_expected).to be(true)
      end
    end
  end

  context "options" do
    it "force-destroy by default should be false" do
      expect(app.options.force_destroy).to be false
    end

    it "timeout by default" do
      expect(app.options.timeout).to eq 7200
    end

    it "audit_mode by default" do
      expect(app.options.audit_mode).to be true
    end

    it "data_path by default" do
      expect(app.options.data_path).to include(".acceptance_data")
    end

    context "force-destroy: true" do
      let(:app_options) do
        { "force_destroy" => true }
      end

      it "should be settable" do
        expect(app.options.force_destroy).to be true
      end
    end

    context "set timeout" do
      let(:app_options) do
        { "timeout" => 10000 }
      end

      it "should be settable" do
        expect(app.options.timeout).to eq 10000
      end
    end

    context "set audit_mode" do
      let(:app_options) do
        { "audit_mode" => false }
      end

      it "should be settable" do
        expect(app.options.audit_mode).to eq false
      end
    end
  end

  context "running suites" do
    let(:suites) { %w{slow fast flash} }

    before do
      allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).with("chef-client").and_return(true)
    end

    context "without chef-client" do
      let(:failure_expected) { true }

      before do
        expect(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).with("chef-client").and_return(false)
      end

      it "should exit with right error message" do
        expect(application_run("fast", "test")).to match(/Could not find chef-client/)
      end
    end

    context "without any suites" do
      let(:failure_expected) { true }
      let(:suites) { [ ] }

      it "should exit with right error message" do
        expect(application_run("all", "test")).to match(/No test suites/)
      end
    end

    context "with non-existing suite" do
      let(:failure_expected) { true }

      it "should exit with right error message" do
        expect(application_run("nosuite", "test")).to match(/No matching test suites found using regex/)
      end
    end

    context "with a single suite" do
      %w{ provision verify destroy }.each do |c|
        context "for #{c} command" do
          let(:fail_command) { false }

          before do
            runner = instance_double(ChefAcceptance::ChefRunner)
            allow(runner).to receive(:run!) do
              raise RuntimeError if fail_command
            end

            allow(runner).to receive(:duration).and_return(10)

            expect(ChefAcceptance::ChefRunner).to receive(:new)
              .with(kind_of(ChefAcceptance::TestSuite), c, kind_of(ChefAcceptance::Options)).and_return(runner)
          end

          it "should output correctly" do
            stdout = application_run("fast", c)
            expect_in_acceptance_logs("fast", c, false, stdout, acceptance_log)
            expect_in_acceptance_logs("fast", "Total", false, stdout, acceptance_log)
            expect_in_acceptance_logs("Run", "Total", false, stdout, acceptance_log)
          end

          context "when failing" do
            let(:fail_command) { true }
            let(:failure_expected) { true }

            it "should output correctly" do
              stdout = application_run("fast", c)
              expect_in_acceptance_logs("fast", c, true, stdout, acceptance_log)
              expect_in_acceptance_logs("fast", "Total", true, stdout, acceptance_log)
              expect_in_acceptance_logs("Run", "Total", true, stdout, acceptance_log)
            end
          end
        end
      end

      context "for test command" do
        let(:fail_command) { false }

        before do
          runner = instance_double(ChefAcceptance::ChefRunner)
          allow(runner).to receive(:run!) do
            raise RuntimeError if fail_command
          end

          allow(runner).to receive(:duration).and_return(10)

          expected_commands.each do |c|
            expect(ChefAcceptance::ChefRunner).to receive(:new).ordered
              .with(kind_of(ChefAcceptance::TestSuite), c, kind_of(ChefAcceptance::Options)).and_return(runner)
          end
        end

        context "without force-destroy" do
          let(:expected_commands) { %w{provision verify destroy} }

          it "should output correctly" do
            stdout = application_run("fast", "test")
            expect_in_acceptance_logs("fast", "provision", false, stdout, acceptance_log)
            expect_in_acceptance_logs("fast", "verify", false, stdout, acceptance_log)
            expect_in_acceptance_logs("fast", "destroy", false, stdout, acceptance_log)
            expect_in_acceptance_logs("fast", "Total", false, stdout, acceptance_log)
            expect_in_acceptance_logs("Run", "Total", false, stdout, acceptance_log)
          end
        end

        context "with force-destroy" do
          let(:expected_commands) { %w{provision verify destroy} }
          let(:app_options) do
            { "force_destroy" => true }
          end

          it "should output correctly" do
            stdout = application_run("fast", "test")
            expect_in_acceptance_logs("fast", "provision", false, stdout, acceptance_log)
            expect_in_acceptance_logs("fast", "verify", false, stdout, acceptance_log)
            expect_in_acceptance_logs("fast", "destroy", false, stdout, acceptance_log)
            expect_in_acceptance_logs("fast", "Total", false, stdout, acceptance_log)
            expect_in_acceptance_logs("Run", "Total", false, stdout, acceptance_log)
          end
        end

        context "when failing" do
          let(:fail_command) { true }
          let(:failure_expected) { true }

          context "without force-destroy" do
            let(:expected_commands) { %w{provision} }

            it "should output correctly" do
              stdout = application_run("fast", "test")
              expect_in_acceptance_logs("fast", "provision", true, stdout, acceptance_log)
              expect_in_acceptance_logs("fast", "Total", true, stdout, acceptance_log)
              expect_in_acceptance_logs("Run", "Total", true, stdout, acceptance_log)
            end
          end

          context "with force-destroy" do
            let(:expected_commands) { %w{provision destroy} }
            let(:app_options) do
              { "force_destroy" => true }
            end

            it "should output correctly" do
              stdout = application_run("fast", "test")
              expect_in_acceptance_logs("fast", "provision", true, stdout, acceptance_log)
              expect_in_acceptance_logs("fast", "force-destroy", true, stdout, acceptance_log)
              expect_in_acceptance_logs("fast", "Total", true, stdout, acceptance_log)
              expect_in_acceptance_logs("Run", "Total", true, stdout, acceptance_log)
            end
          end
        end
      end
    end

    context "with multiple suites" do
      it "runs multiple suites" do
        expect(app).to receive(:run_suite).twice
        application_run("f", "provision")
      end
    end

  end
end
