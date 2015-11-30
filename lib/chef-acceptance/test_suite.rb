require 'chef-acceptance/executable_helper'
require 'mixlib/shellout'
require 'json'
require 'bundler'

module ChefAcceptance
  class TestSuite
    attr_reader :name

    attr_reader :acceptance_cookbook_dir

    attr_accessor :run_recipes

    CORE_ACCEPTANCE_RECIPES = %w(destroy provision verify).freeze

    ACCEPTANCE_COOKBOOK_NAME = 'acceptance-cookbook'.freeze

    def initialize(name)
      @name = name
      @run_recipes = []
      @acceptance_cookbook_dir = File.join(name, '.acceptance', ACCEPTANCE_COOKBOOK_NAME)
    end

    def exist?
      File.exist?(name)
    end

    def run
      verify_run_prerequisites
      create_required_files
      execute_run_command
    end

    def generate
      [acceptance_cookbook_dir, recipes_dir].each do |path|
        FileUtils.mkpath path
      end

      CORE_ACCEPTANCE_RECIPES.each do |file|
        FileUtils.touch(File.join(recipes_dir, "#{file}.rb"))
      end

      File.write(File.join(acceptance_cookbook_dir, 'metadata.rb'),
        "name '#{ACCEPTANCE_COOKBOOK_NAME}'")

      File.write(File.join(name, '.gitignore'),
        "local-mode-cache/\nnodes/\ntmp")
    end

    private

    def temp_dir
      File.join(acceptance_cookbook_dir, 'tmp')
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

    def recipes_dir
      File.join(acceptance_cookbook_dir, 'recipes')
    end

    def verify_run_prerequisites
      unless exist?
        fail <<-EOS
Could not find test suite '#{name}' in the current working \
directory '#{Dir.pwd}'.
EOS
      end

      unless ExecutableHelper.executable_installed? 'chef-client'
        fail "Could not find chef-client in #{ENV['PATH']}"
      end
    end

    def create_required_files
      FileUtils.rmtree temp_dir

      dna = {
        suite_dir: File.expand_path(name)
      }

      FileUtils.mkpath temp_dir
      File.write(dna_json_file, JSON.pretty_generate(dna))

      FileUtils.mkpath chef_dir
      File.write(chef_config_file,
        "cookbook_path '#{File.expand_path(File.join(acceptance_cookbook_dir, '..'))}'")
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
          "#{ACCEPTANCE_COOKBOOK_NAME}::#{recipe}"
        end

        shellout << "-o #{run_list.join(',')}"
      end

      shellout.join(' ')
    end

    def execute_run_command
      Bundler.with_clean_env do
        chef_zero = Mixlib::ShellOut.new(construct_run_command,
                                        cwd: acceptance_cookbook_dir,
                                        live_stream: $stdout)

        chef_zero.run_command

        chef_zero.error!
      end
    end
  end
end
