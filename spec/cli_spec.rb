require 'spec_helper'

describe ChefAcceptance::Cli do
  let(:cli) { described_class.new }

  it 'exits when no config' do
    expect { described_class.new }.to raise_error(SystemExit)
  end

  context 'with config' do
    before do
      ENV['ACCEPTANCE_ROOT'] = "#{Dir.pwd}/spec/support/acceptance"
    end

    it 'loads yaml' do
      expect(cli.config['project_name']).to eq 'chef-acceptance'
    end
  end
end
