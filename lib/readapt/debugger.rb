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
      @original_args = ARGV.clone
    end

    def attach arguments
      @file = Readapt.normalize_path(find(arguments['program']))
      @config = arguments
      @request = :attach
    rescue LoadError => e
      STDERR.puts e.message
    end

    def launch arguments
      @file = Readapt.normalize_path(find(arguments['program']))
      @config = arguments
      @request = :launch
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
        set_program_argv
        run { load File.absolute_path(file) }
        set_original_argv
      end
    end

    def run
      raise RuntimeError, 'Debugger is already running' if @running
      @running = true
      Monitor.start do |snapshot|
        debug snapshot
      end
      yield if block_given?
    rescue Exception => e
      STDERR.puts e.message
      STDERR.puts e.backtrace.join("\n")
    ensure
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
      Monitor.stop
      @request = nil
      Backport.stop if inspector.debugger.launched?
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

    def set_program_argv
      ARGV.clear
      ARGV.concat(@config['programArgs'] || [])
    end

    def set_original_argv
      ARGV.clear
      ARGV.concat @original_args
    end
  end
end
