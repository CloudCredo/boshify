require 'fileutils'
require 'tmpdir'
require 'pathname'

module Boshify
  # Wrapper around filesystem operations
  class Filesystem
    def copy(from, to)
      FileUtils.copy(from, to)
    end

    def mkdir_p(path)
      path.mkpath
    end

    def write_file(options)
      check_file_options!(options)
      file = determine_file_path(options)
      File.open(file.cleanpath, 'w') { |f| f.write(options[:content]) }
      file
    end

    private

    def check_file_options!(options)
      unless options[:content]
        fail ArgumentError, 'File content must be specified'
      end

      # rubocop:disable GuardClause
      unless options[:path] || options[:basename]
        fail ArgumentError, 'Either basename or path must be specified'
      end
    end

    def determine_file_path(options)
      if options[:path]
        options[:path]
      else
        Pathname.new(Dir.mktmpdir) + options[:basename].basename
      end
    end
  end
end
