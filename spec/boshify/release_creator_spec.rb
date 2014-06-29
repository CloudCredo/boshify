require_relative '../../lib/boshify/release_creator'

module Boshify
  describe ReleaseCreator do
    let(:cmd_runner) { double }
    let(:fs) { double }
    before do
      allow(fs).to receive(:mkdir_p).with(Pathname)
      allow(fs).to receive(:write_file).with(path: Pathname, content: String)
      allow(fs).to receive(:copy)
      allow(cmd_runner).to receive(:run).with('tar -ztf /local/postgresql-8.4_8.4.3.orig.tar.gz').and_return('
postgresql-8.4.3/
postgresql-8.4.3/config/
postgresql-8.4.3/COPYRIGHT
postgresql-8.4.3/GNUmakefile.in
postgresql-8.4.3/Makefile
postgresql-8.4.3/README
postgresql-8.4.3/aclocal.m4
postgresql-8.4.3/configure
postgresql-8.4.3/configure.in
postgresql-8.4.3/contrib/
postgresql-8.4.3/doc/
postgresql-8.4.3/src/
postgresql-8.4.3/HISTORY
postgresql-8.4.3/INSTALL
postgresql-8.4.3/src/backend/

')
    end

    describe '#initialize' do
      it 'raises if the filesystem is not provided' do
        expect do
          ReleaseCreator.new(release_dir: '/rel/dir', cmd_runner: cmd_runner)
        end.to raise_error(ArgumentError, 'Filesystem must be provided')
      end
      it 'raises if the release directory is not provided' do
        expect do
          ReleaseCreator.new(filesystem: fs, cmd_runner: cmd_runner)
        end.to raise_error(ArgumentError, 'Release directory must be provided')
      end
      it 'raises if the command runner is not provided' do
        expect do
          ReleaseCreator.new(release_dir: '/rel/dir', filesystem: fs)
        end.to raise_error(ArgumentError, 'Command runner must be provided')
      end
    end

    it 'creates a directory structure equivalent to bosh init release' do
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/blobs'))
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/config'))
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/jobs'))
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/packages'))
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/src'))
      expect(fs).to receive(:write_file).with(path: Pathname.new('/rel/dir/config/blobs.yml'), content: "--- {}\n")
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      rc.create_release(name: 'postgresql', packages: [])
    end

    it 'creates the placeholder blobstore config' do
      expect(fs).to receive(:write_file).with(path: Pathname.new('/rel/dir/config/final.yml'), content: YAML.dump(
        'blobstore' => {
          'provider' => 's3',
          'options' => {
            'bucket_name' => 'postgresql-release',
            'access_key_id' => 'MY_ACCESS_KEY_ID',
            'secret_acces_key' => 'MY_SECRET_ACCESS_KEY',
            'encryption_key' => 'MY_ENCRYPTION_KEY'
          },
        },
        'final_name' => 'postgresql'
      ))
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      rc.create_release(name: 'postgresql', packages: [])
    end
    it 'creates a package spec that references the source tarball' do
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/packages/postgresql'))
      expect(fs).to receive(:write_file).with(path: Pathname.new('/rel/dir/packages/postgresql/spec'), content: YAML.dump(
        'name' => 'postgresql',
        'dependencies' => [],
        'files' => [
          'postgresql/postgresql-8.4_8.4.3.orig.tar.gz'
        ]
      ))
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      rc.create_release(name: 'postgresql', packages: [
        name: 'postgresql',
        source_tarball: Pathname.new('/local/postgresql-8.4_8.4.3.orig.tar.gz')
      ])
    end
    it 'copies the source tarball into place' do
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/blobs/postgresql'))
      expect(fs).to receive(:copy).with(Pathname.new('/local/postgresql-8.4_8.4.3.orig.tar.gz'), Pathname.new('/rel/dir/blobs/postgresql/postgresql-8.4_8.4.3.orig.tar.gz'))
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      rc.create_release(name: 'postgresql', packages: [
        name: 'postgresql',
        source_tarball: Pathname.new('/local/postgresql-8.4_8.4.3.orig.tar.gz')
      ])
    end
    it 'creates a packaging script that configures, makes and installs the tarball' do
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      expect(fs).to receive(:write_file).with(path: Pathname.new('/rel/dir/packages/postgresql/packaging'), content: '#!/bin/bash
set -e
set -u

tar zxvf postgresql/postgresql-8.4_8.4.3.orig.tar.gz
cd postgresql-8.4.3

./configure --prefix=${BOSH_INSTALL_TARGET}

make
make install')
      rc.create_release(name: 'postgresql', packages: [
        name: 'postgresql',
        source_tarball: Pathname.new('/local/postgresql-8.4_8.4.3.orig.tar.gz')
      ])
    end
    it 'creates a job directory' do
      expect(fs).to receive(:mkdir_p).with(Pathname.new('/rel/dir/jobs/postgresql'))
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      rc.create_release(name: 'postgresql', packages: [
        name: 'postgresql',
        source_tarball: Pathname.new('/local/postgresql-8.4_8.4.3.orig.tar.gz')
      ])
    end
    it 'creates an empty monit file' do
      expect(fs).to receive(:write_file).with(path: Pathname.new('/rel/dir/jobs/postgresql/monit'), content: '')
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      rc.create_release(name: 'postgresql', packages: [
        name: 'postgresql',
        source_tarball: Pathname.new('/local/postgresql-8.4_8.4.3.orig.tar.gz')
      ])
    end
    it 'creates a job spec that references the packages' do
      expect(fs).to receive(:write_file).with(path: Pathname.new('/rel/dir/jobs/postgresql/spec'), content: YAML.dump(
        'name' => 'postgresql',
        'packages' => ['postgresql'],
        'templates' => {}
      ))
      rc = ReleaseCreator.new(filesystem: fs, release_dir: '/rel/dir', cmd_runner: cmd_runner)
      rc.create_release(name: 'postgresql', packages: [
        name: 'postgresql',
        source_tarball: Pathname.new('/local/postgresql-8.4_8.4.3.orig.tar.gz')
      ])
    end
  end
end
