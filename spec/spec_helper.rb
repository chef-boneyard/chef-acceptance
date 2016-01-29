$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')

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
    # rubocop:disable Lint/Eval
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
    # rubocop:enable Lint/Eval
  end

  result
end

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
ACCEPTANCE_TEST_DIRECTORY = File.join(PROJECT_ROOT, "test/fixtures/cookbooks/acceptance")

def ensure_project_root
  Dir.chdir(PROJECT_ROOT)
end
