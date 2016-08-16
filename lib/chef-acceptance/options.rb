module ChefAcceptance
  class Options
    attr_reader :timeout
    attr_reader :force_destroy
    attr_reader :audit_mode
    attr_reader :data_path
    attr_reader :chef_client_binary

    DEFAULT_TIMEOUT = 7200

    def initialize(options = {})
      @timeout = options.fetch("timeout", DEFAULT_TIMEOUT)
      @force_destroy = options.fetch("force_destroy", false)
      @audit_mode = options.fetch("audit_mode", true)
      @data_path = options.fetch("data_path", File.expand_path(File.join(Dir.pwd, ".acceptance_data")))
      @chef_client_binary = options.fetch("chef_client_binary", "chef-client")
    end
  end
end
