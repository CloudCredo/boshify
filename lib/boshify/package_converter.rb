module Boshify
  # Converts an operating system package to a BOSH release
  class PackageConverter
    attr_reader :package_source

    def initialize(options)
      @package_source = options[:package_source]
      @downloader = options[:downloader]
      @release_creator = options[:release_creator]
    end

    def create_release_for(package = {})
      @package_source.refresh
      local_path = @downloader.get(
        @package_source.source_tarball_url(package[:name]))
      @release_creator.create_release(name: package[:name], packages: [
        name: package[:name],
        source_tarball: local_path
      ])
    end
  end
end
