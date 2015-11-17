require 'chef-acceptance/executable_helper'
require 'mixlib/shellout'

module ChefAcceptance
  class TestSuite
    attr_reader :name

    attr_reader :acceptance_cookbook_name

    attr_reader :acceptance_cookbook_dir

    attr_reader :recipes_dir

    attr_reader :chef_dir

    attr_reader :chef_config_file

    attr_accessor :run_recipes

    CORE_ACCEPTANCE_RECIPES = %w(destroy provision verify).freeze

    def initialize(name)
      @name = name
      @run_recipes = []
      @acceptance_cookbook_name = 'acceptance-cookbook'
      @acceptance_cookbook_dir = File.join(name, '.acceptance', acceptance_cookbook_name)
      @recipes_dir = File.join(acceptance_cookbook_dir, 'recipes')
      @chef_dir = File.join(acceptance_cookbook_dir, '.chef')
      @chef_config_file = File.join(chef_dir, 'config.rb')
    end

    def exist?
      File.exist?(name)
    end

    def exist!
      unless exist?
        fail <<-EOS
Could not find test suite '#{name}' in the current working \
directory '#{Dir.pwd}'.
EOS
      end
    end

    def run
      unless ExecutableHelper.executable_installed? 'chef-client'
        fail "Could not find chef-client in #{ENV['PATH']}"
      end

      exist!

      shellout = []
      shellout << 'chef-client -z'
      shellout << "-c #{File.expand_path(chef_config_file)}"

      unless run_recipes.empty?
        run_list = run_recipes.collect do |recipe|
          "#{acceptance_cookbook_name}::#{recipe}"
        end

        shellout << "-o #{run_list.join(',')}"
      end

      chef_zero = Mixlib::ShellOut.new(shellout.join(' '),
                                      cwd: acceptance_cookbook_dir,
                                      live_stream: $stdout)

      chef_zero.run_command

      fail "#{chef_zero.stdout}\n#{chef_zero.stderr}" if chef_zero.error?
    end

    def generate
      [acceptance_cookbook_dir, chef_dir, recipes_dir].each do |path|
        FileUtils.mkpath path
      end

      CORE_ACCEPTANCE_RECIPES.each do |file|
        FileUtils.touch(File.join(recipes_dir, "#{file}.rb"))
      end

      File.write(File.join(acceptance_cookbook_dir, 'metadata.rb'),
        "name '#{acceptance_cookbook_name}'")

      File.write(chef_config_file,
        "cookbook_path File.join(File.dirname(__FILE__), '..', '..')")

      File.write(File.join(name, '.gitignore'),
        "local-mode-cache/\nnodes/")
    end
  end
end