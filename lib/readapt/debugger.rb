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

    def initialize machine = Machine.new
      @stack = []
      @frames = {}
      @running = false
      @attached = false
      @request = nil
      @config = {}
      @original_argv = ARGV.clone
      @original_prog = $0
      @machine = machine
      @breakpoints = {}
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
      Thread.find(id)
    end

    def threads
      Thread.all
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
      send_event('process', {
        name: @file
      })
      Monitor.start @file do |snapshot|
        debug snapshot
      end
      yield if block_given?
    rescue StandardError => e
      STDERR.puts "[#{e.class}] #{e.message}"
      STDERR.puts e.backtrace.join("\n")
    rescue SystemExit
      # Ignore
    ensure
      Monitor.stop
      @running = false
      set_original_args
      STDOUT.flush
      STDERR.flush
      changed
      send_event 'terminated', nil
    end

    def output data, category = :console
      send_event('output', {
        output: data,
        category: category
      })
    end

    def get_breakpoint source, line
      @breakpoints["#{source}:#{line}"] || Breakpoint.new(source, line, nil, 0)
    end

    def set_breakpoint source, line, condition, hitcount
      @breakpoints["#{source}:#{line}"] = Breakpoint.new(source, line, condition, hitcount)
    end

    def clear_breakpoints source
      @breakpoints.delete_if { |key, value|
        value.source == source
      }
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
      sleep 0.001 # @todo Trying to let thread data sync
      if snapshot.event == :thread_begin || snapshot.event == :entry
        thr = Thread.find(snapshot.thread_id)
        thr.control = :continue
        send_event('thread', {
          reason: 'started',
          threadId: snapshot.thread_id
        }, true)
        snapshot.control = :continue
      elsif snapshot.event == :thread_end
        thr = thread(snapshot.thread_id)
        thr.control = :continue
        # @threads.delete snapshot.thread_id
        send_event('thread', {
          reason: 'exited',
          threadId: snapshot.thread_id
        })
        snapshot.control = :continue
      else
        confirmed_pause = true
        thread = self.thread(snapshot.thread_id)
        if snapshot.event == :breakpoint
          bp = get_breakpoint(snapshot.file, snapshot.line)
          unless bp.condition.nil? || bp.condition.empty?
            # @type [Binding]
            bnd = thread.frames.first.frame_binding
            begin
              unless bnd.eval(bp.condition)
                confirmed_pause = false
              end
            rescue Exception => e
              STDERR.puts "Breakpoint condition raised an error"
              STDERR.puts "#{snapshot.file}:#{snapshot.line} - `#{bp.condition}`"
              STDERR.puts "[#{e.class}] #{e.message}"
              confirmed_pause = false
            end
          end
          unless !confirmed_pause || bp.hit_condition.nil? || bp.hit_condition.empty?
            bp.hit_cursor += 1
            bnd = thread.frames.first.frame_binding
            begin
              hit_count = bnd.eval(bp.hit_condition)
              if bp.hit_cursor == hit_count
                bp.hit_cursor = 0
              else
                confirmed_pause = false
              end
            rescue Exception => e
              STDERR.puts "Breakpoint condition raised an error"
              STDERR.puts "#{snapshot.file}:#{snapshot.line} - `#{bp.condition}`"
              STDERR.puts "[#{e.class}] #{e.message}"
              confirmed_pause = false
            end
          end
        end
        if confirmed_pause
          changed
          thread.control = :pause
          thread.frames.each do |frm|
            @frames[frm.local_id] = frm
          end
          send_event('stopped', {
            reason: snapshot.event,
            threadId: thread.id
          })
          sleep 0.01 until thread.control != :pause || !Thread.include?(thread.id)
          thread.frames.each do |frm|
            @frames.delete frm.local_id
          end
        else
          thread.control = :continue
        end
        snapshot.control = thread.control
      end
    end

    def set_program_args
      $0 = file
      ARGV.clear
      ARGV.replace(@config['programArgs'] || [])
    end

    def set_original_args
      $0 = @original_prog
      ARGV.clear
      ARGV.replace @original_argv
    end

    def shutdown
      @machine.stop
      exit
    end

    def send_event event, data, wait = false
      changed
      notify_observers event, data
      sleep 0.01 if wait
    end
  end
end
