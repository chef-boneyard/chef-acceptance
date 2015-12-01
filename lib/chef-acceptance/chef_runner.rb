require 'chef-acceptance/executable_helper'
require 'mixlib/shellout'
require 'json'
require 'bundler'
require 'chef-acceptance/acceptance_cookbook'

module ChefAcceptance
  class ChefRunner
    attr_reader :acceptance_cookbook

    attr_reader :test_suite

    attr_accessor :run_recipes

    def initialize(test_suite, options = {})
      @test_suite = test_suite
      @acceptance_cookbook = test_suite.acceptance_cookbook
      @run_recipes = options.fetch(:run_recipes, [])
    end

    def run
      verify_run_prerequisites
      create_required_files
      execute_run_command
    end

    def verify_run_prerequisites
      unless test_suite.exist?
        fail <<-EOS
Could not find test suite '#{test_suite.name}' in the current working \
directory '#{Dir.pwd}'.
EOS
      end

      unless ExecutableHelper.executable_installed? 'chef-client'
        fail "Could not find chef-client in #{ENV['PATH']}"
      end
    end

    def create_required_files
      dna = {
        suite_dir: File.expand_path(test_suite.name)
      }

      FileUtils.rmtree temp_dir
      FileUtils.mkpath temp_dir
      File.write(dna_json_file, JSON.pretty_generate(dna))

      FileUtils.mkpath chef_dir

      chef_config = <<-EOS
cookbook_path '#{File.expand_path(File.join(acceptance_cookbook.root_dir, '..'))}'
node_path '#{File.expand_path(File.join(acceptance_cookbook.root_dir, 'nodes'))}'
      EOS

      File.write(chef_config_file, chef_config)
    end

    def execute_run_command
      Bundler.with_clean_env do
        chef_zero = Mixlib::ShellOut.new(construct_run_command,
                                        cwd: acceptance_cookbook.root_dir,
                                        live_stream: $stdout)

        chef_zero.run_command

        chef_zero.error!
      end
    end

    def construct_run_command
      shellout = []
      shellout << 'chef-client -z'
      shellout << "-c #{File.expand_path(chef_config_file)}"

      if File.exist? dna_json_file
        shellout << "-j #{File.expand_path(dna_json_file)}"
      end

      unless run_recipes.empty?
        run_list = run_recipes.collect do |recipe|
          "#{AcceptanceCookbook::ACCEPTANCE_COOKBOOK_NAME}::#{recipe}"
        end

        shellout << "-o #{run_list.join(',')}"
      end

      shellout.join(' ')
    end

    private

    def temp_dir
      File.join(acceptance_cookbook.root_dir, 'tmp')
    end

    def chef_dir
      File.join(temp_dir, '.chef')
    end

    def chef_config_file
      File.join(chef_dir, 'config.rb')
    end

    def dna_json_file
      File.join(temp_dir, 'dna.json')
    end
  end
end
