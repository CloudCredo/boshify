require 'uri'
require_relative '../../../lib/boshify/ubuntu_packages'

# Ubuntu package source
module Boshify
  describe UbuntuPackages do
    describe 'mirror url' do
      it 'defaults to a US mirror' do
        pkg_source = UbuntuPackages.new(downloader: double, cmd_runner: double)
        expect(pkg_source.mirror_url).to eq(URI.parse('http://us.archive.ubuntu.com/ubuntu/'))
      end
      it 'allows the mirror to be specified' do
        pkg_source = UbuntuPackages.new(
          downloader: double,
          cmd_runner: double,
          mirror_url: 'http://uk.archive.ubuntu.com/ubuntu')
        expect(pkg_source.mirror_url).to eq(URI.parse('http://uk.archive.ubuntu.com/ubuntu/'))
      end
      it 'allows the mirror to be set later' do
        pkg_source = UbuntuPackages.new(downloader: double, cmd_runner: double)
        pkg_source.mirror_url = URI.parse('http://uk.archive.ubuntu.com/ubuntu')
        expect(pkg_source.mirror_url).to eq(URI.parse('http://uk.archive.ubuntu.com/ubuntu/'))
      end
    end

    let(:postgresql_package) do
      'Package: postgresql-8.4
Directory: pool/main/p/postgresql-8.4
Files:
 4a8412b17f1ff447eb60c6c2868fdb8f 1850 postgresql-8.4_8.4.3-1.dsc
 712a5d8f78814d2de2071cf43ed323ac 16853436 postgresql-8.4_8.4.3.orig.tar.gz
 7b2315bdb243d9d63260f72fec0bebc8 34003 postgresql-8.4_8.4.3-1.diff.gz'
    end

    it 'refreshes package metadata' do
      downloader = double
      cmd_runner = double
      expect(downloader).to receive(:get).with(URI.parse(
        'http://us.archive.ubuntu.com/ubuntu/dists/lucid/main/source/'\
        'Sources.bz2'))
      expect(cmd_runner).to receive(:run).with(/bzcat/, quiet: true).and_return(
        exit_code: 0,
        stdout: postgresql_package,
        stderr: '')
      pkg_source = UbuntuPackages.new(
        downloader: downloader,
        cmd_runner: cmd_runner)
      pkg_source.refresh
    end
    it 'raises if the downloaded file cannot be decompressed' do
      downloader = double
      cmd_runner = double
      allow(downloader).to receive(:get)
      expect(cmd_runner).to receive(:run).with(/bzcat/, quiet: true).and_return(
        exit_code: 2,
        stdout: '', stderr: 'bzcat: Compressed file ends unexpectedly;')
      pkg_source = UbuntuPackages.new(
        downloader: downloader,
        cmd_runner: cmd_runner)
      expect { pkg_source.refresh }.to raise_error(
        InvalidPackageMetadataError,
        'Could not decompress: bzcat: Compressed file ends unexpectedly;')
    end
    it 'accepts mirror urls with trailing slashes' do
      downloader = double
      cmd_runner = double
      expect(downloader).to receive(:get).with(URI.parse(
        'http://uk.archive.ubuntu.com/ubuntu/dists/lucid/main/source/'\
        'Sources.bz2'))
      expect(cmd_runner).to receive(:run).with(/bzcat/, quiet: true).and_return(
        exit_code: 0,
        stdout: postgresql_package,
        stderr: '')
      pkg_source = UbuntuPackages.new(
        downloader: downloader,
        cmd_runner: cmd_runner,
        mirror_url: 'http://uk.archive.ubuntu.com/ubuntu/')
      pkg_source.refresh
    end
    it 'determines the source tarball url for a given package' do
      downloader = double
      cmd_runner = double
      allow(downloader).to receive(:get).with(URI.parse(
        'http://us.archive.ubuntu.com/ubuntu/dists/lucid/main/source/'\
        'Sources.bz2'))
      allow(cmd_runner).to receive(:run).with(/bzcat/, quiet: true).and_return(
        exit_code: 0,
        stdout: postgresql_package,
        stderr: '')
      pkg_source = UbuntuPackages.new(
        downloader: downloader,
        cmd_runner: cmd_runner)
      pkg_source.refresh
      expect(pkg_source.source_tarball_url('postgresql-8.4')).to eq(URI.parse(
        'http://us.archive.ubuntu.com/ubuntu/pool/main/p/postgresql-8.4/'\
        'postgresql-8.4_8.4.3.orig.tar.gz'))
    end
    it 'raises if the requested package is not in the index' do
      downloader = double
      cmd_runner = double
      allow(downloader).to receive(:get).with(URI.parse(
        'http://us.archive.ubuntu.com/ubuntu/dists/lucid/main/source/'\
        'Sources.bz2'))
      allow(cmd_runner).to receive(:run).with(/bzcat/, quiet: true).and_return(
        exit_code: 0,
        stdout: postgresql_package,
        stderr: '')
      pkg_source = UbuntuPackages.new(
        downloader: downloader,
        cmd_runner: cmd_runner)
      pkg_source.refresh
      expect do
        pkg_source.source_tarball_url('postgres-8.4')
      end.to raise_error(
        PackageNotFoundError, 'Package postgres-8.4 was not found')
    end
    it 'parses package properties' do
      input = "Package: bzip2\nBinary: libbz2-1.0, libbz2-dev, bzip2, "\
              'lib64bz2-1.0, lib64bz2-dev, lib32bz2-1.0, lib32bz2-dev, '\
              "bzip2-doc\nVersion: 1.0.5-4"
      expect(UbuntuPackages.new.parse(input)).to eq([
        {
          'Package' => 'bzip2',
          'Binary' => 'libbz2-1.0, libbz2-dev, bzip2, lib64bz2-1.0, '\
                      'lib64bz2-dev, lib32bz2-1.0, lib32bz2-dev, bzip2-doc',
          'Version' => '1.0.5-4'
        }
      ])
    end
    it 'parses package properties' do
      input = "Package: bzip2\nBinary: libbz2-1.0, libbz2-dev, bzip2, "\
              'lib64bz2-1.0, lib64bz2-dev, lib32bz2-1.0, lib32bz2-dev, '\
              "bzip2-doc\nVersion: 1.0.5-4"
      expect(UbuntuPackages.new.parse(input)).to eq([
        {
          'Package' => 'bzip2',
          'Binary' => 'libbz2-1.0, libbz2-dev, bzip2, lib64bz2-1.0, '\
                      'lib64bz2-dev, lib32bz2-1.0, lib32bz2-dev, bzip2-doc',
          'Version' => '1.0.5-4'
        }
      ])
    end
    it 'parses multiple packages' do
      input = "Package: bzip2\nBinary: libbz2-1.0, libbz2-dev, bzip2, "\
              'lib64bz2-1.0, lib64bz2-dev, lib32bz2-1.0, lib32bz2-dev, '\
              "bzip2-doc\nVersion: 1.0.5-4\n\n\nPackage: bzr\nBinary: bzr, "\
              "bzr-doc\nVersion: 2.1.1-1"
      expect(UbuntuPackages.new.parse(input).size).to eq 2
    end

    it 'parses multi-value properties' do
      input = 'Package: bzip2
Files:
 adcf07cad22f7ba3cde606fc49162e93 1423 bzip2_1.0.5-4.dsc
 3c15a0c8d1d3ee1c46a1634d00617b1a 841402 bzip2_1.0.5.orig.tar.gz
 49559e20e5bb230a6b1a4221f08ddbb5 76602 bzip2_1.0.5-4.diff.gz'
      expect(UbuntuPackages.new.parse(input)[0]['Files']).to eq([
        {
          name: 'bzip2_1.0.5-4.dsc',
          size_bytes: 1423,
          checksum: 'adcf07cad22f7ba3cde606fc49162e93'
        },
        {
          name: 'bzip2_1.0.5.orig.tar.gz',
          size_bytes: 841_402,
          checksum: '3c15a0c8d1d3ee1c46a1634d00617b1a'
        },
        {
          name: 'bzip2_1.0.5-4.diff.gz',
          size_bytes: 76_602,
          checksum: '49559e20e5bb230a6b1a4221f08ddbb5'
        }
      ])
    end

    it 'copes with values that contain colons' do
      input = 'Package: bzip2
Homepage: http://www.bzip.org/'
      expect(UbuntuPackages.new.parse(input)).to eq([
        { 'Package' => 'bzip2', 'Homepage' => 'http://www.bzip.org/' }
      ])
    end
  end
end
