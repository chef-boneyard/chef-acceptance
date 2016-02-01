require "chef-acceptance/output_formatter"
require "chef-acceptance/chef_runner"
require "chef-acceptance/test_suite"
require "chef-acceptance/executable_helper"

module ChefAcceptance
  class AcceptanceError < StandardError; end

  # Responsible for running one or more suites and
  # displaying statistics about the runs to the user.
  class Application
    attr_reader :force_destroy
    attr_reader :output_formatter

    def initialize(options = {})
      @force_destroy = options.fetch("force_destroy", false)
      @output_formatter = OutputFormatter.new
    end

    def run(suite, command)
      start_time = Time.now
      error = false
      run_summary = true

      begin
        run_suite(suite, command)
      rescue AcceptanceError => e
        error = true
        run_summary = false
        puts "#{e}\n#{e.backtrace.join("\n")}"
      rescue RuntimeError
        # We catch the errors here and do not raise again in
        # order to make a clean exit. Since the errors are already
        # in stdout, we do not print them again.
        error = true
      ensure
        if run_summary
          total_duration = Time.now - start_time
          # Special footer row that gives overall status
          output_formatter.add_row(suite: "", command: "Total", duration: total_duration, error: error)

          puts ""
          puts "chef-acceptance run #{error ? "failed" : "succeeded"}."
          puts output_formatter.generate_output
        end
      end

      # Make sure that exit code reflects the error if we have any
      exit(1) if error
    end

    def run_suite(suite, command)
      test_suite = TestSuite.new(suite)

      unless test_suite.exist?
        raise AcceptanceError, <<-EOS.gsub(/^\s+/, "")
          Could not find test suite '#{test_suite.name}' in the current working directory '#{Dir.pwd}'.
        EOS
      end

      unless ExecutableHelper.executable_installed? "chef-client"
        raise AcceptanceError, "Could not find chef-client in #{ENV['PATH']}"
      end

      if command == "test"
        %w{provision verify destroy}.each do |recipe|
          begin
            run_command(test_suite, recipe)
          rescue RuntimeError => e
            puts "Encountered an error running the recipe #{recipe}: #{e.message}\n#{e.backtrace.join("\n")}"
            if force_destroy && recipe != "destroy"
              puts "--force-destroy specified so attempting to run the destroy recipe"
              run_command(test_suite, "force-destroy")
            end
            raise
          end
        end
      else
        run_command(test_suite, command)
      end
    end

    def run_command(test_suite, command)
      recipe = command == "force-destroy" ? "destroy" : command
      runner = ChefRunner.new(test_suite, recipe)
      error = false
      begin
        runner.run!
      rescue
        error = true
        raise
      ensure
        output_formatter.add_row(suite: test_suite.name, command: command, duration: runner.duration, error: error)
      end
    end

  end
end
