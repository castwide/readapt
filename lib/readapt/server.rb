require 'securerandom'
require 'stringio'

module Readapt
  module Server
    class << self
      attr_accessor :target_in
      attr_accessor :target_pid
    end

    def opening
      Error.adapter = self
      Output.adapter = self
    end

    def receiving data
      Server.target_in.syswrite data
    rescue Errno::EPIPE
      close
    end

    def closing
      Process.kill "KILL", Server.target_pid
    rescue Errno::ESRCH
      # Ignore
    end
  end
end
