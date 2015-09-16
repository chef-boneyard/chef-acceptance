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
    def test
      cookbooks_path = "#{File.dirname(__FILE__)}/../../cookbooks"
      cookbooks = Dir["#{cookbooks_path}/*"]
      cookbooks.each do | cookbook |
        # TODO: don't fret. this is just a quick hack
        command = "cd #{cookbook}/acceptance; kitchen test all"
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
