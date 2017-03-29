require "chef-acceptance/output_formatter"
require "chef-acceptance/chef_runner"
require "chef-acceptance/test_suite"
require "chef-acceptance/executable_helper"
require "chef-acceptance/logger"
require "chef-acceptance/options"

require "thread"

module ChefAcceptance
  class AcceptanceFatalError < StandardError; end

  # Responsible for running one or more suites and
  # displaying statistics about the runs to the user.
  class Application

    WORKER_POOL_SIZE = 3

    attr_reader :options
    attr_reader :output_formatter
    attr_reader :errors
    attr_reader :logger

    def initialize(opt = {})
      @options = ChefAcceptance::Options.new(opt)
      @output_formatter = OutputFormatter.new
      @errors = {}
      @logger = ChefAcceptance::Logger.new(
        log_header: "CHEF-ACCEPTANCE",
        log_path: File.join(options.data_path, "logs", "acceptance.log")
      )
      @error_mutex = Mutex.new
    end

    def log(message)
      logger.log(message)
    end

    def run(suite_regex, command)
      begin
        suites = parse_suites(suite_regex)

        log "Running test suites: #{suites.join(", ")}"

        # Start the overall run timer
        run_start_time = Time.now

        work_queue = Queue.new
        suites.each { |s| work_queue << [s, command] }

        workers = WORKER_POOL_SIZE.times.map do |_i|
          start_worker(work_queue)
        end

        workers.each { |w| w.join }

        total_duration = Time.now - run_start_time
        # Special footer row that gives overall status for run
        output_formatter.add_row(suite: "Run", command: "Total", duration: total_duration, error: run_error?)
        print_summary
      rescue AcceptanceFatalError => e
        log ""
        log e
        exit(1)
      end

      # Make sure that exit code reflects the error if we have any
      exit(1) if run_error?
    end

    def start_worker(queue)
      Thread.new do
        begin
          loop do
            suite, command = queue.pop(true)
            run_suite(suite, command)
          end
        rescue ThreadError
          true
        end
      end
    end

    def run_error?
      !errors.empty?
    end

    # Parse the regex pattern and return an array of matching test suite names
    def parse_suites(regex)
      # Find all directories in cwd
      suites = Dir.glob("*").select { |f| File.directory? f }
      raise AcceptanceFatalError, "No test suites to run in #{Dir.pwd}" if suites.empty?

      # Find all test suites that match the regex pattern
      matched_suites = suites.select { |s| /#{regex}/ =~ s }
      raise AcceptanceFatalError, "No matching test suites found using regex '#{regex}'" if matched_suites.empty?

      # only select the directories containing the .acceptance under them.
      # this way we can skip system directories like 'vendor'
      matched_suites.select do |s|
        File.directory?(File.join(s, ".acceptance"))
      end
    end

    def run_suite(suite, command)
      suite_start_time = Time.now
      test_suite = TestSuite.new(suite)

      unless ExecutableHelper.executable_installed? "chef-client"
        raise AcceptanceFatalError, "Could not find chef-client in #{ENV['PATH']}"
      end

      if command == "test"
        %w{provision verify destroy}.each do |recipe|
          begin
            run_command(test_suite, recipe)
          rescue RuntimeError => e
            log "Encountered an error running the recipe #{recipe}: #{e.message}\n#{e.backtrace.join("\n")}"
            if options.force_destroy && recipe != "destroy"
              log "--force-destroy specified so attempting to run the destroy recipe"
              run_command(test_suite, "force-destroy")
            end
            raise
          end
        end
      else
        run_command(test_suite, command)
      end
    rescue RuntimeError => e
      # We catch the errors here and do not raise again in
      # order to make a clean exit. Since the errors are already
      # in stdout, we do not print them again.
      register_error(suite, e)
    ensure
      suite_duration = Time.now - suite_start_time
      # Capture overall suite run duration
      output_formatter.add_row(suite: suite, command: "Total", duration: suite_duration, error: errors[suite])
    end

    def register_error(suite, exception)
      @error_mutex.synchronize { errors[suite] = exception }
    end

    def run_command(test_suite, command)
      recipe = command == "force-destroy" ? "destroy" : command
      runner = ChefRunner.new(test_suite, recipe, options)
      error = false
      begin
        runner.run!
      rescue
        error = true
        raise
      ensure
        runner.send_log_to_stdout
        output_formatter.add_row(suite: test_suite.name, command: command, duration: runner.duration, error: error)
      end
    end

    def print_summary
      log ""
      log "chef-acceptance run #{run_error? ? "failed" : "succeeded"}"
      output_formatter.generate_output.lines.each do |l|
        log l.chomp
      end
    end

  end
end
