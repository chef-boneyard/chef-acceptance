require "thor"
require "chef-acceptance/version"
require "chef-acceptance/application"
require "chef-acceptance/test_suite"
require "chef-acceptance/acceptance_cookbook"
require "chef-acceptance/executable_helper"

module ChefAcceptance
  class Cli < Thor
    package_name "chef-acceptance"

    #
    # Create core acceptance commands
    #
    AcceptanceCookbook::CORE_ACCEPTANCE_RECIPES.each do |command|
      desc "#{command} TEST_SUITE_REGEX [--log-dir=/log/directory]", "Run #{command}"
      option :log_dir,
        type: :string,
        desc: "Directory to create log files under"
      define_method(command) do |test_suite_regex = ".*"|
        app = Application.new(options)
        app.run(test_suite_regex, command)
      end
    end

    desc "test TEST_SUITE_REGEX [--force-destroy] [--log-dir=/log/directory]", "Run provision, verify and destroy"
    option :log_dir,
      type: :string,
      desc: "Directory to create log files under"
    option :force_destroy,
      type: :boolean,
      desc: "Force destroy phase after any run"
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
