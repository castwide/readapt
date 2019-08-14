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
  end
end
