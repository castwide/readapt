module Readapt
  module Outputter
    @@debugger = nil

    def self.host debugger
      @@debugger = debugger
    end

    def receiving data
      @@debugger.output data, remote[:client]
    end
  end
end
