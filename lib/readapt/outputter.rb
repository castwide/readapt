module Readapt
  module Outputter
    # @!parse include Backport::Adapter

    @@debugger = nil

    def self.host debugger
      @@debugger = debugger
    end

    def receiving data
      @@debugger.output data
    end
  end
end
