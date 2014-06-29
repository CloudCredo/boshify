require 'pathname'
require 'yaml'

module Boshify
  # Responsible for generating BOSH releases
  # rubocop:disable ClassLength
  class ReleaseCreator
    def initialize(options)
      check_options!(options)
      @fs = options[:filesystem]
      @release_dir = Pathname.new(options[:release_dir])
      @cmd_runner = options[:cmd_runner]
    end

    def create_release(release)
      create_empty_release
      create_placeholder_blobstore_config(release)
      create_job(release)
      create_packages(release)
    end

    private

    def check_options!(options)
      unless options[:filesystem]
        fail ArgumentError, 'Filesystem must be provided'
      end
      unless options[:release_dir]
        fail ArgumentError, 'Release directory must be provided'
      end
      # rubocop:disable GuardClause
      unless options[:cmd_runner]
        fail ArgumentError, 'Command runner must be provided'
      end
    end

    def create_empty_release
      create_release_dirs
      generate_empty_blobs_yaml
    end

    def create_release_dirs
      %w(blobs config jobs packages src).each do |dir|
        @fs.mkdir_p(@release_dir + dir)
      end
    end

    def generate_empty_blobs_yaml
      @fs.write_file(path: @release_dir + 'config' + 'blobs.yml',
                     content: YAML.dump({}))
    end

    # rubocop:disable MethodLength
    def create_placeholder_blobstore_config(release)
      @fs.write_file(path: @release_dir + 'config' + 'final.yml',
                     content: YAML.dump(
        'blobstore' => {
          'provider' => 's3',
          'options' => {
            'bucket_name' => "#{release[:name]}-release",
            'access_key_id' => 'MY_ACCESS_KEY_ID',
            'secret_acces_key' => 'MY_SECRET_ACCESS_KEY',
            'encryption_key' => 'MY_ENCRYPTION_KEY'
          }
        },
        'final_name' => release[:name]
      ))
    end

    def create_job(release)
      job_dir = @release_dir + 'jobs' + release[:name]
      @fs.mkdir_p(job_dir)
      @fs.write_file(path: job_dir + 'monit', content: '')
      @fs.write_file(path: job_dir + 'spec', content: job_spec(release))
    end

    def job_spec(release)
      YAML.dump(
        'name' => release[:name],
        'packages' => release[:packages].map { |p| p[:name] },
        'templates' => {}
      )
    end

    def build_path(source_tarball)
      files = @cmd_runner.run("tar -ztf #{source_tarball}").split("\n")
      directory_with_configure(files.map { |p| Pathname.new(p) })
    end

    def directory_with_configure(paths)
      paths.find { |p| p.basename == Pathname.new('configure') }.dirname
    end

    def create_packages(release)
      release[:packages].each do |pkg|
        pkg_dir = make_package_dir(pkg[:name])
        bp = blob_path(pkg)

        generate_package_spec(pkg, pkg_dir, bp)
        copy_blob_into_place(pkg, bp)
        generate_package_script(pkg_dir, bp, pkg[:source_tarball])
      end
    end

    def generate_package_script(pkg_dir, blob_path, source_tarball)
      pkg_script = packaging_script(blob_path, build_path(source_tarball))
      @fs.write_file(path: pkg_dir + 'packaging', content: pkg_script)
    end

    def blob_path(pkg)
      "#{pkg[:name]}/#{pkg[:source_tarball].basename}"
    end

    def make_package_dir(pkg_name)
      pkg_dir = @release_dir + 'packages' + pkg_name
      @fs.mkdir_p(pkg_dir)
      pkg_dir
    end

    def generate_package_spec(pkg, pkg_dir, blob_path)
      @fs.write_file(path: pkg_dir + 'spec',
                     content: package_spec(pkg, blob_path))
    end

    def copy_blob_into_place(pkg, blob_path)
      @fs.mkdir_p(@release_dir + 'blobs' + pkg[:name])
      @fs.copy(pkg[:source_tarball],
               Pathname.new(@release_dir + 'blobs' + blob_path))
    end

    def packaging_script(blob_path, build_dir_path)
      "#!/bin/bash
set -e
set -u

tar zxvf #{blob_path}
cd #{build_dir_path}

./configure --prefix=${BOSH_INSTALL_TARGET}

make
make install"
    end

    def package_spec(pkg, blob_path)
      YAML.dump(
        'name' => pkg[:name],
        'dependencies' => [],
        'files' => [blob_path]
      )
    end
  end
end
