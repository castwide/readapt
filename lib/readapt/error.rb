require 'securerandom'

module Readapt
  module Error
    class << self
      attr_accessor :adapter
    end

    def opening
      @buffer = ''
    end

    def receiving data
      output = ''
      data.each_char do |char|
        @buffer += char
        if open_message.start_with?(@buffer) || @buffer.start_with?(open_message)
          if @buffer.end_with?(close_message)
            msg = @buffer[open_message.length..-(close_message.length+1)]
            exit if msg == '__TERMINATE__'
            Error.adapter.write msg
            @buffer.clear
          end
        else
          output += @buffer
          @buffer.clear
        end
      end
      return if output.empty?
      send_event('output', {
        output: output,
        category: 'stderr'
      })
    end

    def send_event event, data
      obj = {
        type: 'event',
        event: event
      }
      obj[:body] = data unless data.nil?
      json = obj.to_json
      envelope = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
      Error.adapter.write envelope
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
  end
end
