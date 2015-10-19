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
    let(:options) { { destroy: 'passing' } } # TODO: figure out how to send default options

    context 'test-suite suite' do
      let(:test_suite) { 'test-suite' }

      context 'with default destroy option' do
        it 'calls provision, verify, destroy' do
          cli.options = options
          %w(provision verify destroy).each do |cmd|
            expect(capture(:stdout) { cli.send(command, test_suite) }).to match(/the #{cmd} recipe/)
          end
        end

        context 'with passing destroy option' do
          let(:options) { { destroy: 'passing' } }

          it 'calls provision, verify, destroy' do
            cli.options = options
            %w(provision verify destroy).each do |cmd|
              expect(capture(:stdout) { cli.send(command, test_suite) }).to match(/the #{cmd} recipe/)
            end
          end
        end

        context 'with always destroy option' do
          let(:options) { { destroy: 'always' } }

          it 'calls provision, verify, destroy' do
            cli.options = options
            %w(provision verify destroy).each do |cmd|
              expect(capture(:stdout) { cli.send(command, test_suite) }).to match(/the #{cmd} recipe/)
            end
          end
        end

        context 'with never destroy option' do
          let(:options) { { destroy: 'never' } }

          it 'does not call destroy' do
            cli.options = options
            expect(capture(:stdout) { cli.send(command, test_suite) }).not_to match(/the destroy recipe/)
          end
        end

        context 'with invalid destroy option' do
          let(:options) { { destroy: 'foo' } }

          it 'aborts' do
            cli.options = options
            expect { cli.send(command, test_suite) }.to raise_error(/destroy option must be one of/)
          end
        end
      end
    end
  end

  context '#executable_installed!' do
    it 'fails when not found' do
      expect { cli.executable_installed! 'betterlucknexttime' }.to raise_error(/betterlucknexttime executable not installed/)
    end
  end
end
