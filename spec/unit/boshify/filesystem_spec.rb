require 'tempfile'
require_relative '../../../lib/boshify/filesystem'

# Filesystem operations
module Boshify
  describe Filesystem do
    describe '#copy' do
      it 'delegates to file utils copy' do
        expect(FileUtils).to receive(:copy).with('/src/path', '/dest/path')
        Filesystem.new.copy('/src/path', '/dest/path')
      end
    end
    describe '#mkdir_p' do
      it 'makes the directory' do
        path = double
        expect(path).to receive(:mkpath)
        Filesystem.new.mkdir_p(path)
      end
    end
    describe '#write_file' do
      context 'when the path is specified' do
        let(:path) { double }
        let(:f) { double }
        it 'writes the file content' do
          expect(File).to receive(:open).and_yield(f)
          expect(f).to receive(:write).with('file content')
          expect(path).to receive(:cleanpath).and_return('/a/path')
          Filesystem.new.write_file(path: path, content: 'file content')
        end
        it 'returns the file path' do
          allow(File).to receive(:open).and_yield(f)
          allow(f).to receive(:write).with('file content')
          allow(path).to receive(:cleanpath).and_return('/a/path')
          result = Filesystem.new.write_file(path: path,
                                             content: 'file content')
          expect(result).to eq(path)
        end
      end
      context 'when the basename is specified' do
        let(:path) { double }
        let(:f) { double }
        before do
          allow(Dir).to receive(:mktmpdir).and_return('/tmp/dir')
        end
        it 'writes the file content' do
          expect(path).to receive(:basename).and_return('postgresql-8.4.tar.gz')
          expect(File).to receive(:open).and_yield(f)
          expect(f).to receive(:write).with('file content')
          Filesystem.new.write_file(basename: path, content: 'file content')
        end
        it 'returns the file path' do
          allow(path).to receive(:basename).and_return('postgresql-8.4.tar.gz')
          allow(File).to receive(:open).and_yield(f)
          allow(f).to receive(:write).with('file content')
          result = Filesystem.new.write_file(basename: path,
                                             content: 'file content')
          expect(result.basename.to_s).to eq('postgresql-8.4.tar.gz')
        end
      end
      context 'when neither the path nor basename are specified' do
        it 'raises an error' do
          expect do
            Filesystem.new.write_file(content: 'file content')
          end.to raise_error(ArgumentError,
                             'Either basename or path must be specified')
        end
      end
      context 'when the content is not specified' do
        it 'raises an error' do
          expect do
            Filesystem.new.write_file(path: Pathname.new('/a/file/path'))
          end.to raise_error(ArgumentError, 'File content must be specified')
        end
      end
    end
  end
end
