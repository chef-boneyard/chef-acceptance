require 'thor'
require 'mixlib/shellout'
require 'chef-acceptance/version'

module ChefAcceptance
  class Cli < Thor
    ACCEPTANCE_DIR = '.acceptance'.freeze

    ACCEPTANCE_COOKBOOK_NAME = 'acceptance-cookbook'.freeze

    DESTROY_OPTIONS = %w(always never passing).freeze

    package_name 'chef-acceptance'

    desc 'version', 'Print chef-acceptance version'
    def version
      puts ChefAcceptance::VERSION
    end

    #
    # Dynamically build core acceptance commands
    #
    %w(destroy provision verify).each do |command|
      desc command, "Run #{command}"
      define_method(command) do |test_suite|
        executable_installed! 'chef-client'
        test_suite_exist! test_suite

        cookbook_dir = File.expand_path(File.join(test_suite, ACCEPTANCE_DIR, ACCEPTANCE_COOKBOOK_NAME))
        config_file = File.join(cookbook_dir, '.chef', 'config.rb')
        run_list = "#{ACCEPTANCE_COOKBOOK_NAME}::#{command}"

        chef_zero = Mixlib::ShellOut.new("chef-client -z -c #{config_file} -o #{run_list}", cwd: cookbook_dir, live_stream: $stdout)
        chef_zero.run_command
        abort "#{chef_zero.stdout}\n#{chef_zero.stderr}" if chef_zero.error?
      end
    end

    #
    # test command
    # Calls provision, verify and destroy commands
    #
    desc 'test', 'Run provision, verify and destroy'
    option :destroy,
           aliases: '-d',
           default: 'passing',
           desc: "Destroy strategy to use after testing (#{DESTROY_OPTIONS.join(', ')})"
    def test(test_suite)
      executable_installed! 'chef-client'
      test_suite_exist! test_suite

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

    no_commands do
      def test_suite_exist!(test_suite)
        unless File.exist?(test_suite)
          abort <<-EOS
Could not find test suite '#{test_suite}' in the current working directory '#{Dir.pwd}'.
Make sure to have a test suite with a '#{File.join(ACCEPTANCE_DIR, ACCEPTANCE_COOKBOOK_NAME)}' directory.
EOS
        end
      end

      def executable_installed!(executable)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{executable}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          end
        end
        abort "#{executable} executable not installed"
      end
    end
  end
end
