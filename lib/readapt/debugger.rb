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

    attr_reader :stopped

    def initialize
      @stack = []
      @threads = {}
      @frames = {}
      @stopped = Set.new
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

    # @return [Readapt::Thread]
    def thread id
      @threads[id] || Thread::NULL_THREAD
    end

    def frame id
      @frames[id] || Frame::NULL_FRAME
    end

    def launched?
      @request == :launch
    end

    def attached?
      @request == :attach
    end

    def start
      ::Thread.new do
        run { load @file }
      end
    end

    def run
      # raise RuntimeError, 'Debugger is already running' if @running
      set_program_args
      @running = true
      # @threads[::Thread.current.object_id] = Thread.new(::Thread.current.object_id)
      send_event('process', {
        name: @file
      })
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
      Monitor.stop
      @running = false
      set_original_args
      changed
      send_event 'terminated', nil
    end

    def output data, category = :console
      send_event('output', {
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

    # @param [Snapshot]
    # return [void]
    def debug snapshot
      puts snapshot.inspect
      if (snapshot.event == :thread_begin)
        thr = Thread.new(snapshot.thread_id)
        thr.control = :continue
        @threads[snapshot.thread_id] = thr
        send_event('thread', {
          reason: 'started',
          threadId: snapshot.thread_id
        })
        send_event('stopped', {
          reason: 'pause',
          threadId: snapshot.thread_id
        }, true)
        send_event('continued', {
          threadId: snapshot.thread_id,
          allThreadsContinued: false
        }, true)
        snapshot.control = :continue
      elsif (snapshot.event == :thread_end)
        thr = thread(snapshot.thread_id)
        thr.control = :continue
        @stopped.delete thread(snapshot.thread_id)
        @threads.delete snapshot.thread_id
        send_event('thread', {
          reason: 'exited',
          threadId: snapshot.thread_id
        })
        snapshot.control = :continue
      elsif snapshot.event == :initialize
        if snapshot.file != @file
          snapshot.control = :wait
        else
          snapshot.control = :ready
        end
      else
        changed
        thread = self.thread(snapshot.thread_id)
        thread.control = :pause
        @stopped.add thread
        frame = Frame.new(Location.new(snapshot.file, snapshot.line), snapshot.binding_id)
        thread.frames.push frame
        @frames[frame.local_id] = frame
        send_event('stopped', {
          reason: snapshot.event,
          threadId: ::Thread.current.object_id
        }, true)
        if snapshot.event == :entry
          # Make sure information about the stopped thread was processed before
          # continuing
          send_event('continued', {
            threadId: ::Thread.current.object_id,
            allThreadsContinued: false
          }, true)
          thread.control = :continue
        else
          sleep 0.01 until thread.control != :pause || !@threads.key?(thread.id)
        end
        @frames.delete frame.local_id
        thread.frames.delete frame
        @stopped.delete thread
        snapshot.control = thread.control
      end
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

    def send_event event, data, wait = false
      changed
      notify_observers event, data
      sleep 0.01 if wait
    end
  end
end
