require "chef-acceptance/output_formatter"
require "chef-acceptance/chef_runner"
require "chef-acceptance/test_suite"
require "chef-acceptance/executable_helper"

module ChefAcceptance
  # Responsible for running one or more suites and displaying statistics about
  # the runs to the user
  class Application
    attr_reader :force_destroy

    def initialize(options = {})
      @force_destroy = options.fetch(:force_destroy, false)
    end

    def run(suite, command)
      test_suite = TestSuite.new(suite)

      unless test_suite.exist?
        fail <<-EOS.gsub(/^\s+/, "")
          Could not find test suite '#{test_suite.name}' in the current working directory '#{Dir.pwd}'.
        EOS
      end

      unless ExecutableHelper.executable_installed? 'chef-client'
        fail "Could not find chef-client in #{ENV['PATH']}"
      end

      if command == "test"
        %w(provision verify destroy).each do |recipe|
          begin
            run_command(test_suite, recipe)
          rescue RuntimeError => e
            puts "Encountered an error running the recipe #{recipe}: #{e.message}\n#{e.backtrace.join("\n")}"
            if force_destroy && recipe != "destroy"
              puts "--force-destroy specified so attempting to run the destroy recipe"
              run_command(test_suite, "destroy")
            end
            raise
          end
        end
      else
        run_command(test_suite, command)
      end

      # After we run all the suites we need to output the duration and return an
      # non-zero exit code if there was an error
    end

    def run_command(test_suite, command)
      runner = ChefRunner.new(test_suite, command)
      runner.run!
      # TODO add statistics to output
    end

  end
end
