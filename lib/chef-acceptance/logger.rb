require "logger"

module ChefAcceptance
  class Logger
    attr_reader :log_path
    attr_reader :log_header
    attr_reader :file_logger
    attr_reader :stdout_logger

    # Supported options:
    # log_path: full path to the log file
    # log_header: the prefix logger will print when logging messages.
    def initialize(options = {})
      @log_header = options.fetch(:log_header)
      @log_path = options.fetch(:log_path)
      # create the main logs directory
      FileUtils.mkdir_p(File.dirname(log_path))

      @file_logger = create_file_logger
      @stdout_logger = create_stdout_logger

      log("*************@log_header:#{@log_header}\n***************@log_path:#{@log_path}******************************************")
      log("Initialized [#{options[:log_path]}] logger...")
    end

    # logs given message to the acceptance logs and stdout
    def log(message)
      file_logger.info(message)
      stdout_logger.info(message)
    end

    alias_method :<<, :log

    private

    def create_file_logger
      # auto-flush the log file and truncate the log file if it already exists
      log_file = File.open(log_path, File::WRONLY | File::TRUNC | File::CREAT)
      log_file.sync = true

      format_logger_for_acceptance(::Logger.new(log_file))
    end

    def create_stdout_logger
      format_logger_for_acceptance(::Logger.new($stdout))
    end

    def format_logger_for_acceptance(logger)
      logger.progname = log_header
      logger.formatter = proc { |severity, datetime, progname, msg|
        line = "#{progname}::PRAJAKTA::[#{datetime}] #{msg}"
        line = "#{line}\n" unless line.end_with? "\n"
        line
      }

      logger
    end

  end
end
