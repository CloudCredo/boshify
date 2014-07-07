require 'uri'
module Boshify
  class PackageNotFoundError < StandardError; end
  class InvalidPackageMetadataError < StandardError; end

  # Ubuntu package source
  class UbuntuPackages
    attr_reader :mirror_url

    def initialize(options = {})
      @downloader = options[:downloader]
      @cmd_runner = options[:cmd_runner]
      self.mirror_url = options[:mirror_url] || 'http://us.archive.ubuntu.com/ubuntu'
    end

    def mirror_url=(mirror)
      @mirror_url = URI.parse("#{mirror}/")
    end

    def refresh
      @all_packages = packages_hash(
        parse(decompress(download_sources_metadata)))
    end

    def source_tarball_url(package_name)
      unless @all_packages[package_name]
        fail PackageNotFoundError, "Package #{package_name} was not found"
      end
      pkg = @all_packages[package_name]
      mirror_url + "#{pkg['Directory']}/#{original_tarball(pkg)}"
    end

    def parse(input)
      group_package_values(
        as_a_hash(
          parse_multiline_values(
            group_by_whether_pairs(
              split_key_value_pairs(input)))))
    end

    private

    def original_tarball(pkg)
      pkg['Files'].find { |f| f[:name].end_with?('orig.tar.gz') }[:name]
    end

    def download_sources_metadata
      @downloader.get(mirror_url + 'dists/lucid/main/source/Sources.bz2')
    end

    def decompress(local_path)
      result = @cmd_runner.run("bzcat #{local_path}", quiet: true)
      if result[:exit_code] != 0
        fail InvalidPackageMetadataError,
             "Could not decompress: #{result[:stderr]}"
      end
      result[:stdout]
    end

    FILE_KEYS = %w(Files Checksums-Sha1 Checksums-Sha256)

    def split_key_value_pairs(input)
      input.lines.map { |line| line.split(':', 2).map { |f| f.strip } }
    end

    def group_by_whether_pairs(pairs)
      pairs.chunk { |p| p.size == 2 }.to_a
    end

    def parse_multiline_values(pairs)
      # rubocop:disable Next
      pairs.each_with_index do |v, i|
        if !v[0] && FILE_KEYS.include?(pairs[i - 1][1].last[0])
          pairs[i - 1][1].last[1] = remove_empty(v[1]).map do |line|
            file = line[0].split(' ')
            { name: file[2], size_bytes: file[1].to_i, checksum: file[0] }
          end
          pairs[i] = nil
        end
      end
      pairs.compact
    end

    def remove_empty(lines)
      lines.reject { |line| line[0].empty? }
    end

    def as_a_hash(pairs)
      pairs.map { |b, p| Hash[p] if b }.compact
    end

    def group_package_values(pkgs)
      last_pkg_index = -1
      pkgs.each_with_index do |pkg, i|
        if pkg.key?('Package')
          last_pkg_index = i
        else
          pkgs[last_pkg_index].merge!(pkg)
          pkgs[i] = nil
        end
      end
      pkgs.compact
    end

    def packages_hash(pkgs)
      Hash[pkgs.map do |pkg|
        [pkg['Package'], pkg]
      end]
    end
  end
end
