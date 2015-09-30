require 'thor'
require 'yaml'

class ChefAcceptance
  class Cli < Thor
    def initialize(*args)
      super
      @root = Dir.pwd
      @acceptance_yaml = File.join(@root, '.acceptance.yml')
      if !File.exist?(@acceptance_yaml)
        puts ".acceptance.yml file not found in #{@root}. Make sure you are running from an acceptance directory."
        exit 1
      end
      @config = YAML.load_file(@acceptance_yaml)
    end

    desc 'verify', 'Run acceptance tests'
    option :project_version
    option :channel
    def verify
      env_vars = []
      env_vars << "PROJECT_VERSION=#{@config['version']}" if options[:project_version]
      env_vars << "CHANNEL=#{@config['channel']}" if options[:channel]
      system("#{env_vars.join(' ')} kitchen test all")
    end
  end
end
