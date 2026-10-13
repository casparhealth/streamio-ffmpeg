module FFMPEG
  class Error < StandardError
  end

  # Raised when Movie is given a URL (or any other non-local input) instead of a local file.
  class RemoteInputNotAllowed < Error
  end
end
