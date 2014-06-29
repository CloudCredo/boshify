require_relative '../../lib/boshify/package_converter'
module Boshify
  describe PackageConverter do
    let(:pkg_source) { double }
    let(:downloader) { double }
    let(:release_creator) { double }
    let(:conv) { PackageConverter.new(package_source: pkg_source, downloader: downloader, release_creator: release_creator) }

    before do
      allow(downloader).to receive(:get)
      allow(pkg_source).to receive(:refresh)
      allow(pkg_source).to receive(:source_tarball_url)
      allow(release_creator).to receive(:create_release)
    end

    it 'refreshes the package source metadata' do
      expect(pkg_source).to receive(:refresh)
      conv.create_release_for(name: 'postgresql-8.4')
    end

    it 'downloads the source tarball for the package' do
      allow(pkg_source).to receive(:source_tarball_url).and_return('http://example.org/code.tar.gz')
      expect(downloader).to receive(:get).with('http://example.org/code.tar.gz')
      conv.create_release_for(name: 'postgresql-8.4')
    end

    it 'creates a release from the discovered source tarball' do
      allow(pkg_source).to receive(:source_tarball_url).and_return('http://example.org/code.tar.gz')
      allow(downloader).to receive(:get).with('http://example.org/code.tar.gz').and_return('/local/path/code.tar.gz')
      expect(release_creator).to receive(:create_release).with(name: 'postgresql-8.4', packages: [
        name: 'postgresql-8.4',
        source_tarball: '/local/path/code.tar.gz'
      ])
      conv.create_release_for(name: 'postgresql-8.4')
    end

  end
end
