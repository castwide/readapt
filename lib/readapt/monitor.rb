module Readapt
  # The module responsible for stepping through code and providing snapshots.
  #
  # @!method self.start &block
  #   Enable tracepoints. Yield a Snapshot to the provided block for every
  #   stop (breakpoints, steps, etc.).
  #   @yieldparam [Snapshot]
  #   @return [Boolean]
  #
  # @!method self.stop
  #   Disable tracepoints.
  #   @return [Boolean]
  module Monitor
    @@breakpoints = Breakpoints.new

    # @return [Breakpoints]
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
