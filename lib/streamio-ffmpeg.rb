$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'stringio'

require 'ffmpeg/version'
require 'ffmpeg/errors'
require 'ffmpeg/movie'
require 'ffmpeg/io_monkey'
require 'ffmpeg/transcoder'
require 'ffmpeg/encoding_options'

module FFMPEG
  # FFMPEG logs information about its progress when it's transcoding.
  # Jack in your own logger through this method if you wish to.
  #
  # @param [Logger] log your own logger
  # @return [Logger] the logger you set
  def self.logger=(log)
    @logger = log
  end

  # Get FFMPEG logger.
  #
  # @return [Logger]
  def self.logger
    return @logger if @logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    @logger = logger
  end

  # Set the path of the ffmpeg binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffmpeg
  #
  # @param [String] path to the ffmpeg binary
  # @return [String] the path you set
  # @raise Errno::ENOENT if the ffmpeg binary cannot be found
  def self.ffmpeg_binary=(bin)
    if bin.is_a?(String) && !File.executable?(bin)
      raise Errno::ENOENT, "the ffmpeg binary, \'#{bin}\', is not executable"
    end
    @ffmpeg_binary = bin
  end

  # Get the path to the ffmpeg binary, defaulting to 'ffmpeg'
  #
  # @return [String] the path to the ffmpeg binary
  # @raise Errno::ENOENT if the ffmpeg binary cannot be found
  def self.ffmpeg_binary
    @ffmpeg_binary || which('ffmpeg')
  end

  # Get the path to the ffprobe binary, defaulting to what is on ENV['PATH']
  #
  # @return [String] the path to the ffprobe binary
  # @raise Errno::ENOENT if the ffprobe binary cannot be found
  def self.ffprobe_binary
    @ffprobe_binary || which('ffprobe')
  end

  # Set the path of the ffprobe binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffprobe
  #
  # @param [String] path to the ffprobe binary
  # @return [String] the path you set
  # @raise Errno::ENOENT if the ffprobe binary cannot be found
  def self.ffprobe_binary=(bin)
    if bin.is_a?(String) && !File.executable?(bin)
      raise Errno::ENOENT, "the ffprobe binary, \'#{bin}\', is not executable"
    end
    @ffprobe_binary = bin
  end

  DEFAULT_INPUT_FORMAT_WHITELIST = 'mov,mp4,m4a,3gp'.freeze

  # Demuxers ffprobe/ffmpeg may use for an input. Restricting them stops a crafted upload
  # (an HLS/concat playlist renamed to .mp4) from making ffmpeg open other files or URLs.
  #
  # @return [String] comma-separated demuxer names
  def self.input_format_whitelist
    @input_format_whitelist || DEFAULT_INPUT_FORMAT_WHITELIST
  end

  # @param [String, nil] formats comma-separated demuxer names; nil restores the default
  # @raise ArgumentError if formats is blank
  def self.input_format_whitelist=(formats)
    if !formats.nil? && formats.to_s.strip.empty?
      raise ArgumentError, 'input_format_whitelist must not be blank'
    end
    @input_format_whitelist = formats
  end

  # Options placed before every `-i`: only the local file protocol, only whitelisted demuxers.
  #
  # @return [Array<String>]
  def self.input_safety_options
    ['-protocol_whitelist', 'file', '-format_whitelist', input_format_whitelist]
  end

  # Cross-platform way of finding an executable in the $PATH.
  #
  #   which('ruby') #=> /usr/bin/ruby
  # see: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      }
    end
    raise Errno::ENOENT, "the #{cmd} binary could not be found in #{ENV['PATH']}"
  end

end
