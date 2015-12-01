require 'thor'
require 'chef-acceptance/version'
require 'chef-acceptance/chef_runner'
require 'chef-acceptance/test_suite'
require 'chef-acceptance/acceptance_cookbook'
require 'chef-acceptance/executable_helper'

module ChefAcceptance
  class Cli < Thor
    package_name 'chef-acceptance'

    #
    # Create core acceptance commands
    #
    AcceptanceCookbook::CORE_ACCEPTANCE_RECIPES.each do |recipe|
      desc "#{recipe} TEST_SUITE", "Run #{recipe}"
      define_method(recipe) do |test_suite_name|
        test_suite = TestSuite.new(test_suite_name)
        ChefRunner.new(test_suite, run_recipes: [recipe]).run
      end
    end

    desc 'test TEST_SUITE [OPTIONS]', 'Run provision, verify and destroy'
    option :skip_destroy,
           type: :boolean,
           desc: 'Skip destroy phase after any run'
    def test(test_suite_name)
      recipe_list = %w(provision verify)
      recipe_list << 'destroy' if destroy?

      test_suite = TestSuite.new(test_suite_name)
      runner = ChefRunner.new(test_suite, run_recipes: recipe_list)

      begin
        runner.run
      rescue
        if destroy?
          runner.run_recipes = ['destroy']
          runner.run
        end
      end
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
      def destroy?
        !options[:skip_destroy]
      end
    end
  end
end
