$LOAD_PATH << File.join(File.dirname(__FILE__), "../lib")

RSpec.configure do |conf|
  conf.filter_run focus: true
  conf.filter_run_excluding vagrant: true
  conf.run_all_when_everything_filtered = true

  conf.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
ACCEPTANCE_TEST_DIRECTORY = File.join(PROJECT_ROOT, "test/fixtures/cookbooks/acceptance")

def ensure_project_root
  Dir.chdir(PROJECT_ROOT)
end

def acceptance_log_prefix_regex
  /CHEF-ACCEPTANCE::INFO::\[[\d\-\s:]+\]/
end

def duration_regex
  /\d{2}:\d{2}:\d{2}/
end

def acceptance_table_regex(suite_name, phase, error)
  /#{acceptance_log_prefix_regex}.+#{suite_name}.+#{phase}.+#{duration_regex}.+#{error ? "Y" : "N"}.+/
end

def expect_in_acceptance_logs(suite_name, phase, error, *logs)
  logs.each do |log|
    expect(log).to match(acceptance_table_regex(suite_name, phase, error))
  end
end
