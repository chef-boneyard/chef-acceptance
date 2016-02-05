require "spec_helper"
require "chef-acceptance/application"
require "pry"

describe ChefAcceptance::Application do
  let(:app) { ChefAcceptance::Application.new(app_options) }
  let(:app_options) { {} }
  let(:failure_expected) { false }

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
      expect(app.force_destroy).to be false
    end

    context "force-destroy: true" do
      let(:app_options) do
        { "force_destroy" => true }
      end

      it "should be settable" do
        expect(app.force_destroy).to be true
      end
    end
  end

  context "running suites" do
    let(:suites) { [ "slow", "fast", "flash" ] }

    before do
      @acceptance_dir = Dir.mktmpdir
      Dir.chdir @acceptance_dir
      suites.each do |suite|
        Dir.mkdir File.join(@acceptance_dir, suite)
      end

      allow(ChefAcceptance::ExecutableHelper).to receive(:executable_installed?).with("chef-client").and_return(true)
    end

    after do
      FileUtils.rmdir @acceptance_dir if @acceptance_dir
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
              .with(kind_of(ChefAcceptance::TestSuite), c).and_return(runner)
          end

          it "should output correctly" do
            output = application_run("fast", c)
            expect(output).to match(/| fast  | #{c}\s+| 00:00:10 | N     |/)
            expect(output).to match(/| fast  | Total     | 00:00:00 | N     |/)
            expect(output).to match(/| Run   | Total     | 00:00:00 | N     |/)
          end

          context "when failing" do
            let(:fail_command) { true }
            let(:failure_expected) { true }

            it "should output correctly" do
              output = application_run("fast", c)
              expect(output).to match(/| fast  | #{c}\s+| 00:00:10 | Y     |/)
              expect(output).to match(/| fast  | Total     | 00:00:00 | Y     |/)
              expect(output).to match(/| Run   | Total     | 00:00:00 | Y     |/)
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
              .with(kind_of(ChefAcceptance::TestSuite), c).and_return(runner)
          end
        end

        context "without force-destroy" do
          let(:expected_commands) { %w{provision verify destroy} }

          it "should output correctly" do
            expect(application_run("fast", "test")).to include(<<-OUTPUT)
| Suite | Command   | Duration | Error |
| fast  | provision | 00:00:10 | N     |
| fast  | verify    | 00:00:10 | N     |
| fast  | destroy   | 00:00:10 | N     |
| fast  | Total     | 00:00:00 | N     |
| Run   | Total     | 00:00:00 | N     |
OUTPUT
          end
        end

        context "with force-destroy" do
          let(:expected_commands) { %w{provision verify destroy} }
          let(:app_options) do
            { "force_destroy" => true }
          end

          it "should output correctly" do
            expect(application_run("fast", "test")).to include(<<-OUTPUT)
| Suite | Command   | Duration | Error |
| fast  | provision | 00:00:10 | N     |
| fast  | verify    | 00:00:10 | N     |
| fast  | destroy   | 00:00:10 | N     |
| fast  | Total     | 00:00:00 | N     |
| Run   | Total     | 00:00:00 | N     |
OUTPUT
          end
        end

        context "when failing" do
          let(:fail_command) { true }
          let(:failure_expected) { true }

          context "without force-destroy" do
            let(:expected_commands) { %w{provision} }

            it "should output correctly" do
              expect(application_run("fast", "test")).to include(<<-OUTPUT)
| Suite | Command   | Duration | Error |
| fast  | provision | 00:00:10 | Y     |
| fast  | Total     | 00:00:00 | Y     |
| Run   | Total     | 00:00:00 | Y     |
OUTPUT
            end
          end

          context "with force-destroy" do
            let(:expected_commands) { %w{provision destroy} }
            let(:app_options) do
              { "force_destroy" => true }
            end

            it "should output correctly" do
              expect(application_run("fast", "test")).to include(<<-OUTPUT)
| Suite | Command       | Duration | Error |
| fast  | provision     | 00:00:10 | Y     |
| fast  | force-destroy | 00:00:10 | Y     |
| fast  | Total         | 00:00:00 | Y     |
| Run   | Total         | 00:00:00 | Y     |
OUTPUT
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
