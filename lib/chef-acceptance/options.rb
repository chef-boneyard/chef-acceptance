module ChefAcceptance
  class Options
    attr_reader :timeout
    attr_reader :force_destroy
    attr_reader :audit_mode

    DEFAULT_TIMEOUT = 7200

    def initialize(options = {})
      @timeout = options.fetch("timeout", DEFAULT_TIMEOUT)
      @force_destroy = options.fetch("force_destroy", false)
      @audit_mode = options.fetch("audit_mode", true)
    end
  end
end
