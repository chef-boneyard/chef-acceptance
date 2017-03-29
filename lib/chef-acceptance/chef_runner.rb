require "chef-acceptance/executable_helper"
require "mixlib/shellout"
require "json"
require "bundler"
require "chef-acceptance/acceptance_cookbook"
require "chef-acceptance/logger"
require "chef-acceptance/options"

module ChefAcceptance

  # Responsible for generating a CCR shellout and running it
  class ChefRunner
    attr_reader :acceptance_cookbook
    attr_reader :test_suite
    attr_reader :recipe
    attr_reader :duration
    attr_reader :app_options
    attr_reader :suite_logger
    attr_reader :log_path

    def initialize(test_suite, recipe, app_options)
      @test_suite = test_suite
      @acceptance_cookbook = test_suite.acceptance_cookbook
      @recipe = recipe
      @duration = 0
      @app_options = app_options
      @log_path = File.join(app_options.data_path, "logs", test_suite.name, "#{recipe}.log")
      @suite_logger = ChefAcceptance::Logger.new(
        log_header: "#{test_suite.name.upcase}::#{recipe.upcase}",
        log_path: log_path
      )
    end

    def run!
      # prep and create chef attribute and config file
      prepare_required_files

      chef_shellout = build_shellout(
        chef_config_file: chef_config_file,
        dna_json_file: dna_json_file,
        recipe: recipe
      )

      Bundler.with_clean_env do
        begin
          chef_shellout.run_command
        rescue Mixlib::ShellOut::CommandTimeout => e
          suite_logger.log("Command timed out after #{app_options.timeout} secs")
          raise
        end

        # execution_time can return nil and we always want to return a number
        # for duration().
        @duration = chef_shellout.execution_time || 0
        chef_shellout.error! # This will only raise an error if there was one
      end
    end

    def send_log_to_stdout
      puts IO.read(log_path)
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
        node_path "#{node_path}"
        cache_path "#{cache_path}"
        stream_execute_output true
        audit_mode #{app_options.audit_mode ? ":enabled" : ":disabled"}
      EOS
    end

    def prepare_required_files
      FileUtils.rmtree data_path
      FileUtils.mkpath data_path
      create_file(dna_json_file, JSON.pretty_generate(dna))
      create_file(chef_config_file, chef_config_template)
    end

    def build_shellout(options = {})
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

      Mixlib::ShellOut.new(shellout.join(" "), live_stream: suite_logger, timeout: app_options.timeout)
    end

    def data_path
      File.expand_path(File.join(app_options.data_path, "chef", test_suite.name, recipe))
    end

    def chef_config_file
      File.join(data_path, ".chef/config.rb")
    end

    def dna_json_file
      File.join(data_path, "dna.json")
    end

    def node_path
      File.join(data_path, "nodes")
    end

    def cache_path
      # chef will append "cache" to the configured directory.
      data_path
    end

    def create_file(file_path, file_contents)
      FileUtils.mkpath(File.dirname(file_path))
      File.write(file_path, file_contents)
    end
  end
end
