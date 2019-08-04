module Readapt
  class Snapshot
    attr_reader :thread_id
    attr_reader :binding_id
    attr_reader :file
    attr_reader :line
    attr_reader :method_name
    attr_reader :event
    attr_accessor :control

    def initialize thread_id, binding_id, file, line, method_name, event
      @thread_id = thread_id
      @binding_id = binding_id
      @file = file
      @line = line
      @method_name = method_name
      @event = event
      @control = :pause
    end
  end
end
