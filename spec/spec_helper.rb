require 'simplecov'
SimpleCov.start

require 'bundler'
Bundler.require

require 'fileutils'
require 'socket'

FFMPEG.logger = Logger.new(nil)

LEGACY_FIXTURE_FORMATS = 'mov,mp4,m4a,3gp,flv,mpeg,mpegvideo,wav,mp3,image2,jpeg_pipe,png_pipe,bmp_pipe'.freeze

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Fixtures and transcoder outputs predating the demuxer whitelist (flv, mpeg, wav, jpg).
  # Examples tagged :legacy_formats widen it; untagged examples run with the default.
  config.around(:each) do |example|
    next example.run unless example.metadata[:legacy_formats]

    begin
      FFMPEG.input_format_whitelist = LEGACY_FIXTURE_FORMATS
      example.run
    ensure
      FFMPEG.input_format_whitelist = nil
    end
  end
end

def fixture_path
  @fixture_path ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def tmp_path
  @tmp_path ||= File.join(File.dirname(__FILE__), "..", "tmp")
end

# Counts every TCP connection made to it, so a spec can assert that ffmpeg/ffprobe never
# reached the network (any protocol, not only HTTP).
class ConnectionCounter
  attr_reader :port

  def initialize
    @server = TCPServer.new('127.0.0.1', 0)
    @port = @server.addr[1]
    @hits = 0
    @mutex = Mutex.new
    @thread = Thread.new do
      loop do
        client = @server.accept
        @mutex.synchronize { @hits += 1 }
        client.close
      end
    rescue IOError, Errno::EBADF
      nil
    end
  end

  def hits
    @mutex.synchronize { @hits }
  end

  def close
    @server.close
    @thread.join(1)
  end
end

FileUtils.rm_rf(tmp_path)
FileUtils.mkdir_p tmp_path
