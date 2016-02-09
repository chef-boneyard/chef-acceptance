require "logger"

module ChefAcceptance
  class Logger
    attr_reader :log_path
    attr_reader :log_header
    attr_reader :file_logger
    attr_reader :stdout_logger

    # Supported options:
    # base_dir: Base directory for the logs. Primarily used by specs. We
    #   default to current working directory.
    # log_path: relative path of the log file; relative to the given base_dir.
    # log_header: the prefix logger will print when logging messages.
    def initialize(options = {})
      @log_header = options.fetch(:log_header)

      base_dir = options.fetch(:base_dir, Dir.pwd)
      @log_path = File.join(base_dir, options.fetch(:log_path))
      log_directory = File.dirname(log_path)

      # create the main logs directory
      FileUtils.mkdir_p(log_directory)

      @file_logger = create_file_logger
      @stdout_logger = create_stdout_logger

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
        line = "#{progname}::[#{datetime}] #{msg}"
        line = "#{line}\n" unless line.end_with? "\n"
        line
      }

      logger
    end

    # def add_suite_logger(suite_name)
    #   FileUtils.mkdir_p(File.join(log_directory, suite_name))
    #   # create our suite_logger
    # end
  end
end
