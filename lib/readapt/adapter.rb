# frozen_string_literal: true

require 'json'

module Readapt
  module Adapter
    # @!parse include Backport::Adapter

    @@debugger = nil

    def self.host debugger
      @@debugger = debugger
    end

    def self.procid= pid
      @@procid = pid
    end

    def procid
      @@procid
    end

    def open_message
      @@open_message ||= "<readapt-#{procid}>"
    end

    def close_message
      @@close_message ||= "</readapt-#{procid}>"
    end

    def format result
      write_line result.to_protocol.to_json
    end

    def opening
      @@debugger.add_observer self
      @data_reader = DataReader.new
      @data_reader.set_message_handler do |message|
        process message
      end
    end

    def closing
      @@debugger.delete_observer(self)
    end

    def receiving data
      @data_reader.receive data
    end

    def update event, data
      obj = {
        type: 'event',
        event: event
      }
      obj[:body] = data unless data.nil?
      json = obj.to_json
      envelope = "#{open_message}Content-Length: #{json.bytesize}\r\n\r\n#{json}#{close_message}"
      write envelope
      write "#{open_message}__TERMINATE__#{close_message}" if event == 'terminated'
    end

    private

    # @param data [Hash]
    # @return [void]
    def process data
      message = Message.process(data, @@debugger)
      if data['seq']
        json = {
          type: 'response',
          request_seq: data['seq'],
          success: true,
          command: data['command'],
          body: message.body
        }.to_json
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        write "#{open_message}#{envelope}#{close_message}"
        if data['command'] == 'disconnect'
          @@debugger.disconnect
          # @todo It does not appear necessary to close the adapter after
          #   disconnecting the debugger.
          # close
        end
        return unless data['command'] == 'initialize'
        json = {
          type: 'event',
          event: 'initialized'
        }.to_json
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        write "#{open_message}#{envelope}#{close_message}"
      end
    rescue RuntimeError => e
      STDERR.puts "[#{e.class}] #{e.message}"
      STDERR.puts e.backtrace.join
    end
  end
end
