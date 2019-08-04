# frozen_string_literal: true

require 'backport'
require 'observer'
require 'set'

module Readapt
  class Debugger
    include Observable

    attr_reader :monitor

    attr_accessor :file

    def initialize
      @stack = []
      @trace_threads = Set.new
      @active_threads = Set.new
      @running = false
    end

    def launch file
      Thread.new do
        # run { TOPLEVEL_BINDING.instance_eval { load file } }
        run { load File.absolute_path(file) }
        Backport.stop
      end
    end

    def run
      raise RuntimeError, 'Debugger is already running' if @running
      @running = true
      Monitor.start do |snapshot|
        debug snapshot
      end
      yield if block_given?
      Monitor.stop
      @running = false
    end

    def self.run &block
      new.run &block
    end

    private

    def debug snapshot
      changed
      notify_observers snapshot.event, Thread.current.object_id
      frame = Frame.new(Location.new(snapshot.file, snapshot.line), snapshot.binding_id, snapshot.thread_id)
      # frames.push frame
      inspector = Inspector.new(self, frame)
      Adapter.attach inspector
      while Adapter.attached?
        sleep 0.01
      end
      snapshot.control = inspector.control
      # @frames.delete frame
    end
  end
end
