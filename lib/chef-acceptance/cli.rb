require 'thor'
require 'yaml'

class ChefAcceptance
  class Cli < Thor

    attr_accessor :config

    def initialize(*args)
      super
      root = ENV['ACCEPTANCE_ROOT'] || Dir.pwd
      acceptance_yaml = File.join(root, '.acceptance.yml')
      if !File.exist?(acceptance_yaml)
        puts ".acceptance.yml file not found in #{root}. Make sure you are running from an acceptance directory."
        exit 1
      end
      @config = YAML.load_file(acceptance_yaml)
    end

    desc 'verify', 'Run acceptance tests'
    option :project_version
    option :channel
    def verify
      env_vars = []
      env_vars << "PROJECT_VERSION=#{get_option_value['version']}" if options[:project_version]
      env_vars << "CHANNEL=#{get_option_value['channel']}" if options[:channel]
      system("#{env_vars.join(' ')} kitchen test all")
    end

    no_commands {
      def get_option_value(option)
        config[option] || options[option]
      end
    } # no_commands
  end
end
