module ChefAcceptance
  class OutputFormatter
    # TODO merge these two classes into 1 class that stores suite/command info
    # and has a puts method

    def add_row(suite, command, duration, error)
    end

    # Returns a String containing a multi-line table with the phases
    def phase_to_duration_table()
      # Duration comes in as milliseconds - lets change that to a more readable format

      # | SUITE  | PHASE      | DURATION  | ERROR |
      # | suite1 | provision  | 30s       | Y |
      # | suite1 | destroy    | 1m        | N |
      # | suite2 | provision  | 1m 2s     | N |
      # | suite2 | verify     | 2m 10s    | N |
      # | suite2 | destroy    | 60s       | N |
      # | suite2 | total      | 4m 12s    | N |

      # Suite           Status              Time Elapsed
      # ------------------------------------------------
      # gem_versions    success             7:15
      # trivial         failure(provision)  6:15
      # something_else  not_run             0:00
      #                                     13:30
    end

    private

    # Takes in duration as a number of milliseconds and turns it into a
    # pretty output like `1h 20m 30s`
    def pretty_duration(duration)

    end
  end

  class SuiteStatistics
    attr_reader :stats

    def initialize
      @stats = {}
    end

    def add_duration(suite, command, duration)
      stats[suite] ||= {}
      stats[suite][command] ||= {}
      stats[suite][command][:duration] = duration
    end

    def add_error(suite, command, error)
      stats[suite] ||= {}
      stats[suite][command] ||= {}
      stats[suite][command][:error] = error
    end

    # Return a 2D array where each row is an array containing suite name,
    # command, duration and error (or nil)
    def flatten
      flat = []
      stats.each do |suite_name, command_stats|
        command_stats.each do |command_name, stats|
          flat << [suite_name, command_name, stats[:duration], stats[:error]]
        end
      end
      flat
    end
  end
end
