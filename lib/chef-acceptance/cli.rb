require 'thor'
require 'chef-acceptance/version'
require 'chef-acceptance/application'
require 'chef-acceptance/test_suite'
require 'chef-acceptance/acceptance_cookbook'
require 'chef-acceptance/executable_helper'

module ChefAcceptance
  class Cli < Thor
    package_name 'chef-acceptance'

    #
    # Create core acceptance commands
    #
    AcceptanceCookbook::CORE_ACCEPTANCE_RECIPES.each do |command|
      desc "#{command} TEST_SUITE", "Run #{command}"
      define_method(command) do |test_suite|
        run_app(test_suite, command)
      end
    end

    desc 'test TEST_SUITE [--force-destroy]', 'Run provision, verify and destroy'
    option :force_destroy,
           type: :boolean,
           desc: 'Force destroy phase after any run'
    def test(test_suite)
      run_app(test_suite, "test", options)
    end

    desc 'generate NAME', 'Generate acceptance scaffolding'
    def generate(test_suite_name)
      test_suite = TestSuite.new(test_suite_name)

      abort "Test suite '#{test_suite_name}' already exists." if test_suite.exist?

      AcceptanceCookbook.new(File.join(test_suite_name, '.acceptance')).generate

      puts "Run `chef-acceptance test #{test_suite_name}`"
    end

    desc 'version', 'Print chef-acceptance version'
    def version
      puts ChefAcceptance::VERSION
    end

    desc 'info', 'Print chef-acceptance information'
    def info
      puts "chef-acceptance version: #{ChefAcceptance::VERSION}"
      client = ExecutableHelper.executable_installed? 'chef-client'
      puts "chef-client path: #{client ? client : "not found in #{ENV['PATH']}"}"
    end

    no_commands do
      def run_app(test_suite_name, command, options = nil)
        app = if options
                Application.new(options)
              else
                Application.new
              end

        begin
          app.run(test_suite_name, command)
        rescue
          abort "Acceptance failed"
        end
      end
    end
  end
end
