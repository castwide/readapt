require 'securerandom'
require 'stringio'

module Readapt
  module Server
    class << self
      attr_accessor :target_in
    end

    def opening
      Error.adapter = self
      Output.adapter = self
    end

    def receiving data
      Server.target_in.syswrite data
    end
  end
end
