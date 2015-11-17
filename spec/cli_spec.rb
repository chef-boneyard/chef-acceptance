require 'spec_helper'
require 'chef-acceptance/cli'

context 'ChefAcceptance::Cli' do
  let(:cli) { ChefAcceptance::Cli.new }
  let(:command) { nil }
  let(:options) { {} }
  let(:test_suite) { nil }
  let(:error) { nil }

  before(:all) do
    Dir.chdir('test/fixtures/cookbooks/acceptance')
  end

  shared_examples_for 'an invalid test suite' do
    it 'aborts non existing test suite' do
      expect { cli.send(command, 'foo') }.to raise_error(/Could not find test suite 'foo'/)
    end
  end

  shared_examples_for 'a valid command' do
    it 'calls the correct acceptance recipe' do
      expect(capture(:stdout) { cli.send(command, test_suite) }).to match(/the #{command} recipe/)
    end
  end

  shared_examples_for 'a failed command' do
    it 'aborts command with error' do
      expect { cli.send(command, test_suite) }.to raise_error(error)
    end
  end

  context 'verify command' do
    let(:command) { :verify }

    it_behaves_like 'an invalid test suite'

    context 'error-suite suite' do
      let(:test_suite) { 'error-suite' }
      let(:error) { /syntax error, unexpected keyword_end, expecting end-of-input/ }

      it_behaves_like 'a failed command'
    end

    context 'test-suite suite' do
      let(:test_suite) { 'test-suite' }

      it_behaves_like 'a valid command'
    end

    context 'kitchen-suite suite', :vagrant do
      let(:test_suite) { 'kitchen-suite' }

      it_behaves_like 'a valid command'
    end
  end

  context 'provision command' do
    let(:command) { :provision }

    it_behaves_like 'an invalid test suite'

    context 'error-suite suite' do
      let(:test_suite) { 'error-suite' }
      let(:error) { /No such file or directory - nocommand/ }

      it_behaves_like 'a failed command'
    end

    context 'test-suite suite' do
      let(:test_suite) { 'test-suite' }

      it_behaves_like 'a valid command'
    end
  end

  context 'destroy command' do
    let(:command) { :destroy }

    it_behaves_like 'an invalid test suite'

    context 'test-suite suite' do
      let(:test_suite) { 'test-suite' }

      it_behaves_like 'a valid command'
    end

    context 'kitchen-suite suite', :vagrant do
      let(:test_suite) { 'kitchen-suite' }

      it_behaves_like 'a valid command'
    end
  end

  context 'test command' do
    let(:command) { :test }

    context 'test-suite suite' do
      let(:test_suite) { 'test-suite' }

      context 'with default destroy option' do
        it 'calls provision, verify, destroy' do
          %w(provision verify destroy).each do |cmd|
            expect(capture(:stdout) { cli.send(command, test_suite) }).to match(/the #{cmd} recipe/)
          end
        end
      end

      context 'with skip destroy option' do
        let(:options) { { skip_destroy: true } }

        it 'does not call destroy' do
          cli.options = options
          expect(capture(:stdout) { cli.send(command, test_suite) }).not_to match(/the destroy recipe/)
        end
      end
    end
  end

  context 'generate command' do
    let(:command) { :generate }
    let(:test_suite) { 'foo' }

    it 'generates and runs' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir)
        FileUtils.mkpath 'acceptance'
        Dir.chdir 'acceptance'
        expect(capture(:stdout) { cli.send(command, test_suite) }).to match(/chef-acceptance test #{test_suite}/)
        expect { cli.send(command, test_suite) }.to raise_error(/Test suite '#{test_suite}' already exists./)
        cli.options = { destroy: 'always' }
        cli.send(:test, test_suite)
      end
    end
  end
end
