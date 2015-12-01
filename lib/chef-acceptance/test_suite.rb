require 'chef-acceptance/acceptance_cookbook'

module ChefAcceptance
  class TestSuite
    attr_reader :name

    attr_reader :acceptance_cookbook

    def initialize(name, options = {})
      @name = name
      @acceptance_cookbook = options.fetch(:acceptance_cookbook,
        AcceptanceCookbook.new(File.join(Dir.pwd, name, '.acceptance')))
    end

    def exist?
      File.exist?(name)
    end
  end
end
