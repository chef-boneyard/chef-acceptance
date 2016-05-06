require "spec_helper"
require "chef-acceptance/logger"

describe ChefAcceptance::Logger do
  let(:temp_dir) { Dir.mktmpdir }
  let(:log_file) { File.join(Dir.mktmpdir, ".acceptance_data", "logs", "acceptance.log") }

  let(:logger) do
    ChefAcceptance::Logger.new(
      log_header: "CHEF-ACCEPTANCE",
      log_path: log_file
    )
  end

  before do
    FileUtils.rm_rf(File.join(temp_dir, "*"))
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def log_format(message)
    /#{acceptance_log_prefix_regex} #{message}/
  end

  describe "#log" do
    it "logs correctly" do
      logger.log("test-log")

      expect(File.read(log_file)).to match(log_format(/Initialized \[(.*).acceptance_data\/logs\/acceptance.log\] logger.../))
      expect(File.read(log_file)).to match(log_format("test-log"))
    end

    it "overwrites content in an existing file" do
      FileUtils.mkdir_p(File.dirname(log_file))
      File.open(log_file, File::RDWR | File::CREAT) do |f|
        f.write("Some existing content")
      end
      expect(File.read(log_file)).to match("Some existing content")

      logger.log("test-log")
      expect(File.read(log_file)).not_to match("Some existing content")
      expect(File.read(log_file)).to match(log_format(/Initialized \[(.*).acceptance_data\/logs\/acceptance.log\] logger.../))
      expect(File.read(log_file)).to match(log_format("test-log"))
    end
  end

end
