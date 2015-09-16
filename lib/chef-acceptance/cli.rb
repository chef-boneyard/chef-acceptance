require 'thor'

class ChefAcceptance
  class Cli < Thor
    desc 'list COOKBOOKS', 'list all acceptance cookbooks'
    def list
      cookbooks_path = "#{File.dirname(__FILE__)}/../../cookbooks"
      cookbooks = Dir["#{cookbooks_path}/*"]
      cookbooks.each do | cookbook |
        puts File.basename(cookbook)
      end
    end

    desc 'run TESTS', 'run acceptance tests'
    option :omnibus_project
    option :omnibus_version
    def test
      env_vars = []
      env_vars << "PROJECT_NAME=#{options[:omnibus_project]}" if options[:omnibus_project]
      env_vars << "PROJECT_VERSION=#{options[:omnibus_version]}" if options[:omnibus_version]
      cookbooks_path = "#{File.dirname(__FILE__)}/../../cookbooks"
      cookbooks = Dir["#{cookbooks_path}/*"]
      cookbooks.each do | cookbook |
        # TODO: don't fret. this is just a quick hack
        command = "cd #{cookbook}/acceptance; #{env_vars.join(' ')} kitchen test all"
        system(command)
      end
    end

    desc 'destroy INSTANCES', 'destroy instances'
    def destroy
      cookbooks_path = "#{File.dirname(__FILE__)}/../../cookbooks"
      cookbooks = Dir["#{cookbooks_path}/*"]
      cookbooks.each do | cookbook |
        # TODO: don't fret. this is just a quick hack
        command = "cd #{cookbook}/acceptance; kitchen destroy"
        system(command)
      end
    end

    # private
    #
    # def for_cookbooks
    #   cookbooks_path = "#{File.dirname(__FILE__)}/../../cookbooks"
    #   cookbooks = Dir["#{cookbooks_path}/*"]
    #   cookbooks.each do | cookbook |
    #     yield
    #   end
    # end
  end
end
