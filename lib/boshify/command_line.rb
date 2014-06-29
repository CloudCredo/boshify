require 'optparse'
require 'pathname'

module Boshify
  # Command line argument processing
  class CommandLine
    def initialize(options)
      unless options[:program_name]
        fail ArgumentError, 'Program name must be specified'
      end
      unless options[:package_converter]
        fail ArgumentError, 'Package converter must be specified'
      end
      @program_name = Pathname.new(options[:program_name]).basename
      @package_converter = options[:package_converter]
    end

    def run(args)
      with_options(args) do |options|
        begin
          use_mirror_if_specified(options[:mirror])
          @package_converter.create_release_for(name: options[:package])
          { exit_code: 0, stdout: "Package #{options[:package]} converted" }
        rescue => e
          { exit_code: 1, stdout: e.message }
        end
      end
    end

    private

    def with_options(args)
      options = parse(args)
      if options[:package]
        yield options
      else
        { exit_code: 0, stdout: @parser.help }
      end
      rescue OptionParser::MissingArgument
        { exit_code: 1, stdout: @parser.help }
    end

    def use_mirror_if_specified(mirror_url)
      return unless mirror_url
      @package_converter.package_source.mirror_url = mirror_url
    end

    def parse(args)
      options = {}
      @parser = OptionParser.new do |cmd_opts|
        cmd_opts.banner = "#{@program_name} [options]"
        add_package_option(cmd_opts, options)
        add_mirror_option(cmd_opts, options)
        add_help_option(cmd_opts, options)
      end
      @parser.parse!(args)
      options
    end

    def add_package_option(cmd_opts, options)
      cmd_opts.on('-p', '--package PACKAGE', 'Ubuntu source package') do |p|
        options[:package] = p
      end
    end

    def add_mirror_option(cmd_opts, options)
      cmd_opts.on('-m',
                  '--mirror [MIRROR]',
                  'Alternate Ubuntu mirror URL') do |m|
        options[:mirror] = m
      end
    end

    def add_help_option(cmd_opts, options)
      cmd_opts.on('-h', '--help', 'Print help') do
        options[:help] = true
      end
    end
  end
end
