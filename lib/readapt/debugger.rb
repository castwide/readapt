# frozen_string_literal: true

require 'backport'
require 'observer'
require 'set'

module Readapt
  class Debugger
    include Observable
    include Finder

    attr_reader :monitor

    attr_reader :file

    def initialize
      @stack = []
      @trace_threads = Set.new
      @active_threads = Set.new
      @running = false
      @attached = false
      @request = nil
      @config = {}
      @original_argv = ARGV.clone
    end

    def config arguments, request
      @file = Readapt.normalize_path(find(arguments['program']))
      @config = arguments
      @request = request
    rescue LoadError => e
      STDERR.puts e.message
    end

    def launched?
      @request == :launch
    end

    def attached?
      @request == :attach
    end

    def start
      Thread.new do
        run { load @file }
      end
    end

    def run
      # raise RuntimeError, 'Debugger is already running' if @running
      set_program_args
      @running = true
      Monitor.start do |snapshot|
        debug snapshot
      end
      yield if block_given?
    rescue StandardError => e
      STDERR.puts e.message
      STDERR.puts e.backtrace.join("\n")
    rescue SystemExit
      # Ignore
    ensure
      set_original_args
      Monitor.stop
      @running = false
      changed
      notify_observers 'terminated', nil
    end

    def output data, category = :console
      changed
      notify_observers('output', {
        output: data,
        category: category
      })
    end

    def disconnect
      shutdown if launched?
      @request = nil
    end

    def self.run &block
      new.run &block
    end

    private

    def debug snapshot
      changed
      notify_observers('stopped', {
        reason: snapshot.event,
        threadId: Thread.current.object_id
      })
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

    def set_program_args
      ARGV.clear
      ARGV.replace(@config['programArgs'] || [])
    end

    def set_original_args
      ARGV.clear
      ARGV.replace @original_argv
    end

    def shutdown
      Backport.stop
      exit
    end
  end
end
