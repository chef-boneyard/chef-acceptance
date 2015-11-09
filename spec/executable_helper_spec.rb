require 'spec_helper'
require 'chef-acceptance/executable_helper'

context 'ChefAcceptance::ExecutableHelper' do
  let(:executable_helper) { ChefAcceptance::ExecutableHelper }

  it 'is callable' do
    executable_helper.executable_installed?('')
  end

  it 'raises an exception' do
    expect(executable_helper.executable_installed?('foo')).to be false
  end
end
