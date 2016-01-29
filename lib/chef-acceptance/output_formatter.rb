module ChefAcceptance
  class OutputFormatter
    attr_reader :rows

    def initialize
      # The headers are the first row in the table
      @rows = []
    end

    def add_row(columns)
      rows << [columns[:suite], columns[:command], columns[:duration], columns[:error]]
    end

    # Returns a String containing a multi-line table with the phases
    # | Suite  | Command   | Duration   | Error |
    # | suite1 | provision | 00:00:00   | N     |
    # | suite1 | verify    | 00:00:01   | Y     |
    # | suite1 | destroy   | 00:00:10   | N     |
    # | suite2 | provision | 00:01:40   | N     |
    # | suite2 | verify    | 00:16:40   | N     |
    # | suite2 | destroy   | 2777:46:40 | N     |
    def generate_output
      rows.each do |row|
        # Change duration to a more readable format
        row[2] = pretty_duration(row[2])

        # Error comes in as true or false - change to 'Y' or 'N'
        row[3] = row[3] ? "Y" : "N"
      end

      # The headers are the first row in the table
      @rows = [["Suite", "Command", "Duration", "Error"]] + rows

      # Compute the longest item in each column so we can make the column
      # that wide
      column_widths = [0, 0, 0, 0]
      rows.each do |row|
        row.each_with_index do |item, index|
          column_widths[index] = item.length if item.length > column_widths[index]
        end
      end

      # Add a space on either side of the longest item
      column_widths.map! do |c|
        c += 2
      end

      # Now output each item with the correct padding
      rows.each_with_index do |row, row_index|
        row.each_with_index do |item, column_index|
          item = " #{item}"
          rows[row_index][column_index] = item.ljust(column_widths[column_index])
        end
      end

      output = ""
      rows.each do |row|
        output << "|#{row.join("|")}|\n"
      end

      output
    end

    private

    # Takes in duration as a number of seconds and turns it into a
    # pretty output like `1:23:59`
    def pretty_duration(duration)
      secs = duration.to_i % 60
      duration_in_mins = duration / 60
      mins = duration_in_mins.to_i % 60
      duration_in_hours = duration_in_mins / 60
      hours = duration_in_hours.to_i

      output = []
      [hours, mins, secs].each do |t|
        if t.to_s.length == 1
          output << "0#{t}"
        else
          output << t.to_s
        end
      end
      output.join(":")
    end

  end
end
