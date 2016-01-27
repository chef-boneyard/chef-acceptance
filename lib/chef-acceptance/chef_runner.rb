require 'chef-acceptance/executable_helper'
require 'mixlib/shellout'
require 'json'
require 'bundler'
require 'chef-acceptance/acceptance_cookbook'
require 'chef-acceptance/shellout_builder'

module ChefAcceptance
  class ChefRunner
    attr_reader :acceptance_cookbook
    attr_reader :test_suite
    attr_reader :shellout_builder

    def initialize(test_suite)
      @test_suite = test_suite
      @acceptance_cookbook = test_suite.acceptance_cookbook
      @shellout_builder = ShelloutBuilder.new(cwd: acceptance_cookbook.root_dir)
    end

    def run!(recipe)
      unless test_suite.exist?
        fail <<-EOS.gsub(/^\s+/, "")
          Could not find test suite '#{test_suite.name}' in the current working directory '#{Dir.pwd}'.
        EOS
      end

      unless ExecutableHelper.executable_installed? 'chef-client'
        fail "Could not find chef-client in #{ENV['PATH']}"
      end

      # prep and create chef attribute and config file
      prepare_required_files

      shellout_builder.with_chef_config_file(chef_config_file)
      shellout_builder.with_dna_json_file(dna_json_file)
      shellout_builder.with_recipe("#{AcceptanceCookbook::ACCEPTANCE_COOKBOOK_NAME}::#{recipe}")
      chef_shellout = shellout_builder.build

      Bundler.with_clean_env do
        chef_shellout.run_command
        chef_shellout.error!
      end
    end

    private

    def dna
      {
        'chef-acceptance' => {
          'suite-dir' => File.expand_path(test_suite.name)
        }
      }
    end

    def chef_config_template
      <<-EOS.gsub(/^\s+/, "")
        cookbook_path '#{File.expand_path(File.join(acceptance_cookbook.root_dir, '..'))}'
        node_path '#{File.expand_path(File.join(acceptance_cookbook.root_dir, 'nodes'))}'
        stream_execute_output true
      EOS
    end

    def prepare_required_files
      FileUtils.rmtree temp_dir
      FileUtils.mkpath temp_dir
      File.write(dna_json_file, JSON.pretty_generate(dna))

      FileUtils.mkpath chef_dir
      File.write(chef_config_file, chef_config_template)
    end

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
