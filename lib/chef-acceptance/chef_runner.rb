require "chef-acceptance/executable_helper"
require "mixlib/shellout"
require "json"
require "bundler"
require "chef-acceptance/acceptance_cookbook"
require "chef-acceptance/logger"
require "tmpdir"

module ChefAcceptance

  # Responsible for generating a CCR shellout and running it
  class ChefRunner
    attr_reader :acceptance_cookbook
    attr_reader :test_suite
    attr_reader :recipe
    attr_reader :duration
    attr_reader :log_dir

    def initialize(test_suite, recipe, log_dir: File.join(Dir.pwd, ".acceptance_logs"))
      @test_suite = test_suite
      @acceptance_cookbook = test_suite.acceptance_cookbook
      @recipe = recipe
      @duration = 0
      @log_dir = log_dir
    end

    def run!
      # prep and create chef attribute and config file
      prepare_required_files

      chef_shellout = build_shellout(
        cwd: acceptance_cookbook.root_dir,
        chef_config_file: chef_config_file,
        dna_json_file: dna_json_file,
        recipe: recipe
      )

      Bundler.with_clean_env do
        chef_shellout.run_command
        # execution_time can return nil and we always want to return a number
        # for duration().
        @duration = chef_shellout.execution_time || 0
        chef_shellout.error! # This will only raise an error if there was one
      end
    end

    private

    def dna
      {
        "chef-acceptance" => {
          "suite-dir" => File.expand_path(test_suite.name),
        },
      }
    end

    def chef_config_template
      # Note: we include a .shared directory in the cookbook path in order to
      # allow suites to share infrastructure. This is currently not supported for
      # projects to use externally. There will eventually be a better way to do this.
      <<-EOS.gsub(/^\s+/, "")
        cookbook_path [
          #{File.expand_path('..', acceptance_cookbook.root_dir).inspect},
          #{File.expand_path('../../../.shared', acceptance_cookbook.root_dir).inspect}
        ]
        node_path #{File.expand_path('nodes', temp_dir).inspect}
        stream_execute_output true
        audit_mode :enabled
      EOS
    end

    def prepare_required_files
      FileUtils.rmtree temp_dir
      FileUtils.mkpath temp_dir
      File.write(dna_json_file, JSON.pretty_generate(dna))

      FileUtils.mkpath chef_dir
      File.write(chef_config_file, chef_config_template)
    end

    def build_shellout(options = {})
      cwd = options.fetch(:cwd, Dir.pwd)
      recipe = options.fetch(:recipe)
      chef_config_file = options.fetch(:chef_config_file)
      dna_json_file = options.fetch(:dna_json_file)

      shellout = []
      shellout << "chef-client -z"
      shellout << "-c #{chef_config_file}"
      shellout << "--force-formatter"
      shellout << "-j #{dna_json_file}"
      shellout << "-o #{AcceptanceCookbook::ACCEPTANCE_COOKBOOK_NAME}::#{recipe}"
      shellout << "--no-color"

      suite_logger = ChefAcceptance::Logger.new(
        log_header: "#{test_suite.name.upcase}::#{recipe.upcase}",
        log_path: File.join(log_dir, test_suite.name, "#{recipe}.log")
      )
      Mixlib::ShellOut.new(shellout.join(" "), cwd: cwd, live_stream: suite_logger, timeout: 7200)
    end

    def temp_dir
      File.join(Dir.tmpdir, "chef-acceptance", test_suite.name)
    end

    def chef_dir
      File.join(temp_dir, ".chef")
    end

    def chef_config_file
      File.expand_path(File.join(chef_dir, "config.rb"))
    end

    def dna_json_file
      File.expand_path(File.join(temp_dir, "dna.json"))
    end
  end
end
