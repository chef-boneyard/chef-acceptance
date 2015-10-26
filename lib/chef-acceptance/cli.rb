require 'thor'
require 'mixlib/shellout'
require 'chef-acceptance/version'

module ChefAcceptance
  class Cli < Thor
    ACCEPTANCE_COOKBOOK_NAME = 'acceptance-cookbook'.freeze

    CORE_ACCEPTANCE_COMMANDS = %w(destroy provision verify).freeze

    DESTROY_OPTIONS = %w(always never passing).freeze

    package_name 'chef-acceptance'

    #
    # Create core acceptance commands
    #
    CORE_ACCEPTANCE_COMMANDS.each do |command|
      desc "#{command} TEST_SUITE", "Run #{command}"
      define_method(command) do |test_suite|
        chef_client_installed!

        suite = TestSuite.new(test_suite)

        suite.exist!

        shellout = []
        shellout << 'chef-client -z'
        shellout << "-c #{File.expand_path(suite.chef_config_file)}"
        shellout << "-o #{ACCEPTANCE_COOKBOOK_NAME}::#{command}"

        chef_zero = Mixlib::ShellOut.new(shellout.join(' '),
                                         cwd: suite.acceptance_cookbook_dir,
                                         live_stream: $stdout)
        chef_zero.run_command

        abort "#{chef_zero.stdout}\n#{chef_zero.stderr}" if chef_zero.error?
      end
    end

    desc 'test TEST_SUITE [OPTIONS]', 'Run provision, verify and destroy'
    option :destroy,
           banner: 'STRATEGY',
           aliases: '-d',
           default: 'passing',
           desc: "Destroy strategy to use after testing (#{DESTROY_OPTIONS.join(', ')})"
    def test(test_suite)
      unless DESTROY_OPTIONS.include? options[:destroy]
        abort "destroy option must be one of: #{DESTROY_OPTIONS.join(', ')}"
      end

      begin
        provision(test_suite)
        verify(test_suite)
      rescue => e
        puts e
      ensure
        destroy(test_suite) unless options[:destroy] == 'never'
      end
    end

    desc 'generate NAME', 'Generate acceptance scaffolding'
    def generate(name)
      suite = TestSuite.new(name)

      abort "Test suite '#{name}' already exists." if suite.exist?

      [suite.acceptance_cookbook_dir, suite.chef_dir, suite.recipes_dir].each do |path|
        FileUtils.mkpath path
      end

      CORE_ACCEPTANCE_COMMANDS.each do |file|
        FileUtils.touch(File.join(suite.recipes_dir, "#{file}.rb"))
      end

      File.write(File.join(suite.acceptance_cookbook_dir, 'metadata.rb'),
        "name '#{ACCEPTANCE_COOKBOOK_NAME}'")

      File.write(suite.chef_config_file,
        "cookbook_path File.join(File.dirname(__FILE__), '..', '..')")

      File.write(File.join(name, '.gitignore'),
        "local-mode-cache/\nnodes/")

      puts "Run `chef-acceptance test #{name}`"
    end

    desc 'version', 'Print chef-acceptance version'
    def version
      puts ChefAcceptance::VERSION
    end

    desc 'info', 'Print chef-acceptance information'
    def info
      puts "chef-acceptance version: #{ChefAcceptance::VERSION}"
      client = executable_installed? 'chef-client'
      puts "chef-client path: #{client ? client : "not found in #{ENV['PATH']}"}"
    end

    no_commands do
      def executable_installed?(executable)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{executable}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          end
        end
        false
      end

      def chef_client_installed!
        unless executable_installed? 'chef-client'
          abort "Could not find chef-client in #{ENV['PATH']}"
        end
      end

      TestSuite = Struct.new(:name) do
        # TODO: sanitize input

        def exist?
          File.exist?(name)
        end

        def exist!
          unless self.exist?
            abort <<-EOS
  Could not find test suite '#{name}' in the current working \
  directory '#{Dir.pwd}'.
  EOS
          end
        end

        def acceptance_cookbook_dir
          File.join(name, '.acceptance', ACCEPTANCE_COOKBOOK_NAME)
        end

        def recipes_dir
          File.join(acceptance_cookbook_dir, 'recipes')
        end

        def chef_dir
          File.join(acceptance_cookbook_dir, '.chef')
        end

        def chef_config_file
          File.join(chef_dir, 'config.rb')
        end
      end
    end
  end
end
