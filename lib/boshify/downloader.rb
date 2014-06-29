require 'httparty'
require 'uri'

module Boshify
  class DownloadError < StandardError; end

  # Downloads remote resources to disk
  class Downloader
    def initialize(options = {})
      @filesystem = options[:filesystem]
    end

    def get(url)
      bn = Pathname.new(URI.parse(url.to_s).path).basename
      r = HTTParty.get(url)
      unless r.ok?
        fail DownloadError, "The resource could not be retrieved: #{url}"
      end
      @filesystem.write_file(basename: bn, content: r.body)
    end
  end
end
