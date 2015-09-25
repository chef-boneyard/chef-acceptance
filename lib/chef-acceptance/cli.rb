require 'thor'
require 'yaml'
require 'git'
require 'fileutils'
require 'command_line_reporter'

class ChefAcceptance
  class Cli < Thor
    include CommandLineReporter

    def initialize(*args)
      super
      @project_root = "#{File.dirname(__FILE__)}/../.."
      @suites_dir = File.join(@project_root, '.suites')
      @acceptance_yaml = ENV['ACCEPTANCE_YAML'] || 'acceptance.yml'
      @config = YAML.load_file(File.join(@project_root, @acceptance_yaml))
    end

    desc 'list-suites', 'List configured test suites'
    def list_suites
      sorted = @config.sort_by { |k,v| k['name'] }
      sorted.each { |suite| puts "#{suite['name']} (#{suite['git']}:#{suite['branch']})" }
    end

    desc 'download-suite [*SUITE_NAME]', 'Download a list of suites. No argument will download all available test suites'
    def download_suite(*name)
      if name.empty?
        puts "No suite names provided. Downlading all suites."
        @config.each { |suite| clone(suite) }
      else
        selected_suites = @config.select { |suite| name.include?(suite['name']) }
        # TODO: parallelize
        selected_suites.each { |suite | clone(suite) }
      end

      print_errors
    end

    desc 'update-suites [*SUITE_NAME]', 'Update a list of suites. No argument will update all available test suites'
    def update_suite(*name)
      if name.empty?
        puts "No suite names provided. Updating all suites."
        @config.each { |suite| pull(suite) }
      else
        selected_suites = @config.select { |suite| name.include?(suite['name']) }
        # TODO: parallelize
        selected_suites.each { |suite | pull(suite) }
      end

      print_errors
    end

    desc 'delete-suite [*SUITE_NAME]', 'Delete downloaded suites'
    option :all, :type => :boolean
    def delete_suite(*name)
      if options[:all]
        puts 'Removing all test suites'
        FileUtils.rm_rf(@suites_dir)
      elsif name.empty?
        puts "No suite names provided. Specify a list of suites or use '--all'"
        return
      else
        selected_suites = @config.select { |suite| name.include?(suite['name']) }
        puts "Removing test suites:\n#{name.join("\n")}"
        selected_suites.each { |suite | FileUtils.rm_rf(File.join(@suites_dir, suite['name'])) }
      end
    end

    desc 'test *SUITE_NAME', 'Run acceptance tests'
    option :project, :required => true
    option :project_version, :default => 'latest'
    option :channel, :default => 'stable' # stable, current, unstable(artifactory)
    def test(*name)
      if name.empty?
        puts "Must provide at least one test suite"
        exit 1
      end
      env_vars = [ "PROJECT_NAME=#{options[:project]}" ]
      env_vars << "PROJECT_VERSION=#{options[:project_version]}"
      env_vars << "PROJECT_CHANNEL=#{options[:channel]}"
      selected_suites = @config.select { |suite| name.include?(suite['name']) }
      selected_suites.each do | suite |
        # TODO: don't fret. this is just a quick hack
        # TODO: rewrite to use kithen api
        command = "cd #{suite['name']}/acceptance; #{env_vars.join(' ')} kitchen test all"
        system(command)
      end
    end

    # TODO: rewrite to use kithen api
    desc 'destroy', 'Destroy all kitchen instances'
    def destroy
      Dir["#{@suites_dir}/*"].each do | suite |
        # TODO: don't fret. this is just a quick hack
        command = "cd #{suite}/acceptance; kitchen destroy -c 10"
        system(command)
      end
    end

    no_commands {
      #
      # Clone github repositories and checkout the configured branch
      #
      # @param suite [Hash] test suite configuration
      #
      def clone(suite)
        puts "Cloning #{suite['git']}"
        begin
          g = Git.clone(suite['git'], suite['name'], :path => @suites_dir)
          checkout(suite)
        rescue Git::GitExecuteError => e
          case e.message
          when /already exists and is not an empty directory/
            add_error "#{suite['name']}(#{suite['git']}) suite already exists. Try `update-suite #{suite['name']}`."
          when /Repository not found/
            add_error "#{suite['name']}(#{suite['git']}) repository not found."
          else
            add_error e
          end
        end
      end

      #
      # Pull github repositories and checkout the configured branch
      #
      # @param suite [Hash] test suite configuration
      #
      def pull(suite)
        puts "Updating #{suite['git']}"
        begin
          g = git_open(suite['name'])
          g.pull
          checkout(suite, :git_base => g)
        rescue Git::GitExecuteError, ArgumentError => e
          case e.message
          when /path does not exist/
            add_error "#{suite['name']}(#{File.join(@suites_dir, suite['name'])}) suite not found."
          else
            add_error e
          end
        end
      end

      #
      # Checkout the configured branch for a test suite
      #
      # @param suite [Hash] test suite configuration
      # @option options [Git::Base] pass an existing Git::Base object
      #
      def checkout(suite, options = {})
        puts "  Checking out branch #{suite['branch']}"
        begin
          if options[:git_base]
            options[:git_base].checkout(suite['branch'])
          else
            git_open(suite['name']).checkout(suite['branch'])
          end
        rescue Git::GitExecuteError => e
          case e.message
          when /pathspec '#{suite['branch']}' did not match any file\(s\) known to git/
            add_error "'#{suite['branch']}' branch not found for #{suite['name']}(#{suite['git']})"
          else
            add_error e
          end
        end
      end

      #
      # Open a test suite for Git operations
      #
      # @param suite_name [String] test suite name
      #
      # @return [Git::Base] the Git::Base instance
      #
      def git_open(suite_name)
        Git.open(File.join(@suites_dir, suite_name))
      end

      #
      # Collection for storing runtime errors
      #
      # @param error [String] error description
      #
      def add_error(error)
        @errors ||= []
        @errors << error
      end

      #
      # Prints error collection on new lines
      #
      def print_errors
        if @errors
          puts "\nErrors"
          puts @errors.join("\n")
        end
      end
    } # end no_commands
  end
end
