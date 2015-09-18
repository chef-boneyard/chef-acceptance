require 'spec_helper'

describe ChefAcceptance::Cli do
  let(:cli) { described_class.new }

  it 'goes' do
    cli.config
    cli.list_suites
    cli.download_suite
    cli.update_suite
    cli.delete_suite('all')
  end
end
