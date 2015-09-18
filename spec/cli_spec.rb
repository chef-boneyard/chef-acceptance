require 'spec_helper'

describe ChefAcceptance::Cli do
  let(:cli) { described_class.new }

  it 'goes' do
    cli.list_suites
    cli.download_suite('chef-acceptance-example')
    cli.download_suite
    cli.update_suite('chef-acceptance-example')
    cli.update_suite
    cli.delete_suite('chef-acceptance-example')
    cli.options = {:all => true}
    cli.delete_suite
  end
end
