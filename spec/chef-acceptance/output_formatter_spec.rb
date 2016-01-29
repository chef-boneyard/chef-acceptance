require "spec_helper"
require "chef-acceptance/output_formatter"

describe ChefAcceptance::OutputFormatter do
  let(:formatter) { ChefAcceptance::OutputFormatter.new }
  let(:test_rows) {
    unformatted_rows.map do |row|
      row = {suite: row[0], command: row[1], duration: row[2], error: row[3]}
    end
  }

  context "when there are no rows" do
    let(:unformatted_rows) { [] }

    it "outputs only the headers" do
      test_rows.each do |r|
        formatter.add_row(r)
      end
      expect(formatter.generate_output).to eq("| Suite | Command | Duration | Error |\n")
    end
  end

  context "when there is a single row" do
    let(:unformatted_rows) {
      [
        ["suite2", "destroy", 10000000000, false]
      ]
    }

    it "outputs successfully" do
      test_rows.each do |r|
        formatter.add_row(r)
      end
      expect(formatter.generate_output).to eq(<<-TABLE.gsub(/^\s+/, "")
      | Suite  | Command | Duration      | Error |
      | suite2 | destroy | 2777777:46:40 | N     |
      TABLE
      )
    end
  end

  context "when there are many rows" do
    let(:unformatted_rows) {
      [
        ["suite1", "provision", 1, false],
        ["suite1", "verify", 1000, true],
        ["suite1", "destroy", 10000, false],
        ["suite2", "provision", 100000, false],
        ["suite2", "verify", 1000000, false],
        ["suite2", "destroy", 10000000000, false],
      ]
    }

    it "outputs successfully" do
      test_rows.each do |r|
        formatter.add_row(r)
      end
      expect(formatter.generate_output).to eq(<<-TABLE.gsub(/^\s+/, "")
      | Suite  | Command   | Duration      | Error |
      | suite1 | provision | 00:00:01      | N     |
      | suite1 | verify    | 00:16:40      | Y     |
      | suite1 | destroy   | 02:46:40      | N     |
      | suite2 | provision | 27:46:40      | N     |
      | suite2 | verify    | 277:46:40     | N     |
      | suite2 | destroy   | 2777777:46:40 | N     |
      TABLE
      )
    end
  end

end
