require 'thor'
require 'chef-acceptance/version'
require 'chef-acceptance/test_suite'
require 'chef-acceptance/executable_helper'

module ChefAcceptance
  class Cli < Thor
    DESTROY_OPTIONS = %w(always never passing).freeze

    package_name 'chef-acceptance'

    #
    # Create core acceptance commands
    #
    TestSuite::CORE_ACCEPTANCE_RECIPES.each do |recipe|
      desc "#{recipe} TEST_SUITE", "Run #{recipe}"
      define_method(recipe) do |test_suite_name|
        test_suite = TestSuite.new(test_suite_name)
        test_suite.run_recipes = [recipe]

        begin
          test_suite.run
        rescue => e
          abort e.message
        end
      end
    end

    desc 'test TEST_SUITE [OPTIONS]', 'Run provision, verify and destroy'
    option :destroy,
           banner: 'STRATEGY',
           aliases: '-d',
           default: 'passing',
           desc: "Destroy strategy to use after testing (#{DESTROY_OPTIONS.join(', ')})"
    def test(test_suite_name)
      unless DESTROY_OPTIONS.include? options[:destroy]
        abort "destroy option must be one of: #{DESTROY_OPTIONS.join(', ')}"
      end

      test_suite = TestSuite.new(test_suite_name)

      recipe_list = %w(provision verify)
      recipe_list << 'destroy' if destroy?

      test_suite.run_recipes = recipe_list
      begin
        test_suite.run
      rescue => e
        puts e.message

        if destroy?
          test_suite.run_recipes = ['destroy']
          test_suite.run
        end

        abort
      end
    end

    desc 'generate NAME', 'Generate acceptance scaffolding'
    def generate(test_suite_name)
      test_suite = TestSuite.new(test_suite_name)

      abort "Test suite '#{test_suite_name}' already exists." if test_suite.exist?

      begin
        test_suite.generate
      rescue => e
        abort e.message
      end

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
        options[:destroy] != 'never'
      end
    end
  end
end
