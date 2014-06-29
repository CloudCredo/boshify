require_relative '../../lib/boshify/command_line'

module Boshify
  describe CommandLine do

    describe '#initialize' do
      it 'raises when the program name is not provided' do
        expect do
          CommandLine.new(package_converter: double)
        end.to raise_error(ArgumentError, 'Program name must be specified')
      end

      it 'raises when the package converter is not provided' do
        expect do
          CommandLine.new(program_name: 'boshify')
        end.to raise_error(ArgumentError, 'Package converter must be specified')
      end
    end

    let(:converter) { double }

    let(:cmd) do
      cmd = CommandLine.new(program_name: 'boshify', package_converter: converter)
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
        cmd = CommandLine.new(program_name: '/long/path/to/boshify', package_converter: double)
        expect(cmd.run([''])).to eq(exit_code: 0, stdout: expected_help_text)
      end

      it 'shows command line help when no arguments are specified' do
        expect(cmd.run([''])).to eq(exit_code: 0, stdout: expected_help_text)
      end

      it 'shows command line help when --help is specified' do
        expect(cmd.run(['--help'])).to eq(exit_code: 0, stdout: expected_help_text)
      end

      it 'returns a non-zero exit code when a package is not specified' do
        expect(cmd.run(['-p'])).to eq(exit_code: 1, stdout: expected_help_text)
      end
    end
    describe 'package conversion' do

      it 'attempts to convert the package when a package is specified' do
        expect(converter).to receive(:create_release_for).with(name: 'postgresql-8.4')
        cmd.run(['-p', 'postgresql-8.4'])
      end

      it 'returns a zero exit code when the package is converted successfully' do
        expect(converter).to receive(:create_release_for).with(name: 'postgresql-8.4')
        expect(cmd.run(['-p', 'postgresql-8.4'])).to eq(exit_code: 0, stdout: 'Package postgresql-8.4 converted')
      end

      it 'returns a non-zero exit code when the package cannot be converted' do
        expect(converter).to receive(:create_release_for).and_raise(RuntimeError, 'Problem downloading package')
        expect(cmd.run(['-p', 'postgresql-8.4'])).to eq(exit_code: 1, stdout: 'Problem downloading package')
      end

    end
  end
end
