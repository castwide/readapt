# frozen_string_literal: true

module Readapt
  # Information about the state of the debugger.
  #
  class Snapshot
    # @return [Integer]
    attr_reader :thread_id

    # @return [String]
    attr_reader :file

    # @return [Integer]
    attr_reader :line

    # The reason for pausing the debugging, e.g., "breakpoint" or "step"
    # @return [String, Symbol]
    attr_reader :event

    # @return [Symbol]
    attr_accessor :control

    # @param thread_id [Integer]
    # @param binding_id [Integer]
    # @param file [String]
    # @param line [Integer]
    # @param method_name [Symbol]
    # @param event [String, Symbol]
    # @param depth [Integer]
    def initialize thread_id, file, line, event
      @thread_id = thread_id
      @file = file
      @line = line
      @event = event
      @control = :pause
    end
  end
end
