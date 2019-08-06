# frozen_string_literal: true

module Readapt
  # Information about the state of the debugger.
  #
  class Snapshot
    # @return [Integer]
    attr_reader :thread_id

    # @return [Integer]
    attr_reader :binding_id

    # @return [String]
    attr_reader :file

    # @return [Integer]
    attr_reader :line

    # @return [Symbol]
    attr_reader :method_name

    # The reason for pausing the debugging, e.g., "breakpoint" or "step"
    # @return [String, Symbol]
    attr_reader :event

    # @return [Integer]
    attr_reader :depth

    # @return [Symbol]
    attr_accessor :control

    # @param thread_id [Integer]
    # @param binding_id [Integer]
    # @param file [String]
    # @param line [Integer]
    # @param method_name [Symbol]
    # @param event [String, Symbol]
    # @param depth [Integer]
    def initialize thread_id, binding_id, file, line, method_name, event, depth
      @thread_id = thread_id
      @binding_id = binding_id
      @file = file
      @line = line
      @method_name = method_name
      @event = event
      @depth = depth
      @control = :pause
    end
  end
end
