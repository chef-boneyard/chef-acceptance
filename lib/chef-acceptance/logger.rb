require "logger"

module ChefAcceptance
  class Logger
    attr_reader :log_directory
    attr_reader :acceptance_logger
    attr_reader :stdout_logger
    attr_reader :suite_loggers

    def initialize(base_dir = Dir.pwd)
      @log_directory = File.join(base_dir, ".acceptance_logs")
      @suite_loggers = []

      # create the main logs directory
      FileUtils.mkdir_p(log_directory)

      @acceptance_logger = create_acceptance_logger
      @stdout_logger = create_stdout_logger

      log("Initialized acceptance logger...")
    end

    # logs given message to the acceptance logs and stdout
    def log(message)
      acceptance_logger.info(message)
      stdout_logger.info(message)
    end

    private

    def create_acceptance_logger
      # auto-flush the log file and truncate the log file if it already exists
      log_file = File.open(File.join(log_directory, "acceptance.log"),
        File::WRONLY | File::TRUNC | File::CREAT)
      log_file.sync = true

      format_logger_for_acceptance(::Logger.new(log_file))
    end

    def create_stdout_logger
      format_logger_for_acceptance(::Logger.new($stdout))
    end

    def format_logger_for_acceptance(logger)
      logger.progname = "CHEF-ACCEPTANCE"
      logger.formatter = proc { |severity, datetime, progname, msg|
        "#{progname}::#{severity}::[#{datetime}] #{msg}\n"
      }

      logger
    end

    # def add_suite_logger(suite_name)
    #   FileUtils.mkdir_p(File.join(log_directory, suite_name))
    #   # create our suite_logger
    # end
  end
end
