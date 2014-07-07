require_relative '../../../lib/boshify/command_line'

# Command line handling
module Boshify
  describe CommandLine do

    describe '#initialize' do
      context 'when the program name is not provided' do
        it 'raises' do
          expect do
            CommandLine.new(package_converter: double)
          end.to raise_error(ArgumentError, 'Program name must be specified')
        end
      end
      context 'when the package converter is not provided' do
        it 'raises' do
          expect do
            CommandLine.new(program_name: 'boshify')
          end.to raise_error(ArgumentError,
                             'Package converter must be specified')
        end
      end
    end

    let(:converter) { double }

    subject do
      CommandLine.new(program_name: 'boshify', package_converter: converter)
    end

    describe 'command line options' do
      let(:expected_help_text) do
        'boshify [options]
    -p, --package PACKAGE            Ubuntu source package
    -m, --mirror [MIRROR]            Alternate Ubuntu mirror URL
    -h, --help                       Print help
'
      end

      it 'does not include the program name leading path' do
        subject = CommandLine.new(program_name: '/long/path/to/boshify',
                                  package_converter: double)
        expect(subject.run([''])).to eq(exit_code: 0,
                                        stdout: expected_help_text,
                                        stderr: '')
      end

      context 'when no arguments are specified' do
        it 'shows command line help' do
          expect(subject.run([''])).to eq(exit_code: 0,
                                          stdout: expected_help_text,
                                          stderr: '')
        end
      end

      context 'when --help is specified' do
        it 'shows command line help' do
          expect(subject.run(['--help'])).to eq(exit_code: 0,
                                                stdout: expected_help_text,
                                                stderr: '')
        end
      end

      context 'when a package is not specified' do
        it 'returns a non-zero exit code' do
          expect(subject.run(['-p'])).to eq(exit_code: 1,
                                            stdout: expected_help_text,
                                            stderr: '')
        end
      end

    end

    describe 'package conversion' do

      it 'attempts to convert the package' do
        expect(converter).to receive(:create_release_for).with(
          name: 'postgresql-8.4')
        subject.run(['-p', 'postgresql-8.4'])
      end

      context 'when the package is converted' do
        it 'returns a zero exit code' do
          expect(converter).to receive(:create_release_for).with(
            name: 'postgresql-8.4')
          expect(subject.run(['-p', 'postgresql-8.4'])).to eq(
            exit_code: 0,
            stdout: 'Package postgresql-8.4 converted',
            stderr: '')
        end
      end

      context 'when the package cannot be converted' do
        it 'returns a non-zero exit code' do
          expect(converter).to receive(:create_release_for).and_raise(
            RuntimeError, 'Problem downloading package')
          expect(subject.run(['-p', 'postgresql-8.4'])).to eq(
            exit_code: 1,
            stdout: '',
            stderr: 'Problem downloading package')
        end
      end

    end
  end
end
