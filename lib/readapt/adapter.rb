# frozen_string_literal: true

require 'json'

module Readapt
  module Adapter
    # @!parse include Backport::Adapter

    @@debugger = nil

    def self.host debugger
      @@debugger = debugger
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
      envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
      write envelope
    end

    private

    # @param data [Hash]
    # @return [void]
    def process data
      # @todo Better solution than nil frames
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
        write envelope
        close if data['command'] == 'disconnect'
        return unless data['command'] == 'initialize'
        json = {
          type: 'event',
          event: 'initialized'
        }.to_json
        envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
        write envelope
      end
    rescue RuntimeError => e
      STDERR.puts "[#{e.class}] #{e.message}"
      STDERR.puts e.backtrace.join
    end
  end

  class DataReader
    def initialize
      @in_header = true
      @content_length = 0
      @buffer = String.new
    end

    # Declare a block to be executed for each message received from the
    # client.
    #
    # @yieldparam [Hash] The message received from the client
    def set_message_handler &block
      @message_handler = block
    end

    # Process raw data received from the client. The data will be parsed
    # into messages based on the JSON-RPC protocol. Each message will be
    # passed to the block declared via set_message_handler. Incomplete data
    # will be buffered and subsequent data will be appended to the buffer.
    #
    # @param data [String]
    def receive data
      data.each_char do |char|
        @buffer.concat char
        if @in_header
          prepare_to_parse_message if @buffer.end_with?("\r\n\r\n")
        else
          parse_message_from_buffer if @buffer.bytesize == @content_length
        end
      end
    end

    private

    def prepare_to_parse_message
      @in_header = false
      @buffer.each_line do |line|
        parts = line.split(':').map(&:strip)
        if parts[0] == 'Content-Length'
          @content_length = parts[1].to_i
          break
        end
      end
      @buffer.clear
    end

    def parse_message_from_buffer
      begin
        msg = JSON.parse(@buffer)
        @message_handler.call msg unless @message_handler.nil?
      rescue JSON::ParserError => e
        Solargraph::Logging.logger.warn "Failed to parse request: #{e.message}"
        Solargraph::Logging.logger.debug "Buffer: #{@buffer}"
      ensure
        @buffer.clear
        @in_header = true
        @content_length = 0
      end
    end
  end
end
