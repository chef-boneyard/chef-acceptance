require "thor"
require "chef-acceptance/version"
require "chef-acceptance/application"
require "chef-acceptance/options"
require "chef-acceptance/test_suite"
require "chef-acceptance/acceptance_cookbook"
require "chef-acceptance/executable_helper"

module ChefAcceptance
  class Cli < Thor
    package_name "chef-acceptance"

    #
    # Define shared options
    #
    option_timeout = [
      :timeout,
      type: :numeric,
      desc: "Override default chef-client timeout. (Default: #{ChefAcceptance::Options::DEFAULT_TIMEOUT})",
    ]

    option_audit_mode = [
      :audit_mode,
      type: :boolean,
      desc: "Enable or disable audit_mode (Default: true)",
    ]

    #
    # Create core acceptance commands
    #
    AcceptanceCookbook::CORE_ACCEPTANCE_RECIPES.each do |command|
      desc "#{command} TEST_SUITE_REGEX", "Run #{command}"
      option(*option_timeout)
      option(*option_audit_mode)
      define_method(command) do |test_suite_regex = ".*"|
        app = Application.new(options)
        app.run(test_suite_regex, command)
      end
    end

    desc "test TEST_SUITE_REGEX", "Run provision, verify and destroy"
    option :force_destroy,
           type: :boolean,
           desc: "Force destroy phase after any run"
    option(*option_timeout)
    option(*option_audit_mode)
    def test(test_suite_regex = ".*")
      app = Application.new(options)
      app.run(test_suite_regex, "test")
    end

    desc "generate NAME", "Generate acceptance scaffolding"
    def generate(name)
      abort "Test suite '#{name}' already exists." if File.exist?(name)
      AcceptanceCookbook.new(File.join(name, ".acceptance")).generate
      puts "Run `chef-acceptance test #{name}`"
    end

    desc "version", "Print chef-acceptance version"
    def version
      puts ChefAcceptance::VERSION
    end

    desc "info", "Print chef-acceptance information"
    def info
      puts "chef-acceptance version: #{ChefAcceptance::VERSION}"
      client = ExecutableHelper.executable_installed? "chef-client"
      puts "chef-client path: #{client ? client : "not found in #{ENV['PATH']}"}"
    end
  end
end
