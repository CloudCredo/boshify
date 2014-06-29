require 'httparty'
require 'pathname'
require 'uri'
require_relative '../../lib/boshify/downloader'

module Boshify
  describe Downloader do
    let(:fs) { double }
    context 'remote resource exists' do
      it 'downloads remote resources to disk' do
        expect(HTTParty).to receive(:get).with('http://example.org/download/postgresql-8.4.tar.gz').and_return(double(body: 'content', ok?: true))
        expect(fs).to receive(:write_file).with(basename: Pathname.new('postgresql-8.4.tar.gz'), content: 'content')
        Downloader.new(filesystem: fs).get('http://example.org/download/postgresql-8.4.tar.gz')
      end
      it 'returns the path to the downloaded file' do
        allow(HTTParty).to receive(:get).with('http://example.org/download/postgresql-8.4.tar.gz').and_return(double(body: 'content', ok?: true))
        allow(fs).to receive(:write_file).with(basename: Pathname.new('postgresql-8.4.tar.gz'), content: 'content').and_return(Pathname.new('/path/to/file'))
        download = Downloader.new(filesystem: fs).get('http://example.org/download/postgresql-8.4.tar.gz')
        expect(download).to respond_to(:to_path)
      end
    end
    it 'accepts a uri' do
      expect(HTTParty).to receive(:get).with(URI.parse('http://example.org/download/postgresql-8.4.tar.gz')).and_return(double(body: 'content', ok?: true))
      expect(fs).to receive(:write_file).with(basename: Pathname.new('postgresql-8.4.tar.gz'), content: 'content')
      Downloader.new(filesystem: fs).get(URI.parse('http://example.org/download/postgresql-8.4.tar.gz'))
    end
    context 'remote resource does not exist' do
      it 'raises an error' do
        expect(HTTParty).to receive(:get).with('http://example.org/download/postgresql-8.4.tar.gz').and_return(double(body: 'content', ok?: false))
        expect(fs).not_to receive(:write_file)
        expect do
          Downloader.new(filesystem: fs).get('http://example.org/download/postgresql-8.4.tar.gz')
        end.to raise_error(DownloadError, 'The resource could not be retrieved: http://example.org/download/postgresql-8.4.tar.gz')
      end
    end
  end
end
