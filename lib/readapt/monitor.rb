module Readapt
  module Monitor
    @@breakpoints = Breakpoints.new

    def self.breakpoints
      @@breakpoints
    end

    def self.set_breakpoints bps
      @@breakpoints = bps
    end

    def self.update
      know_breakpoints
    end

    @@breakpoints.add_observer self
  end
end
