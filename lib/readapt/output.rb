module Readapt
  module Output
    class << self
      attr_accessor :adapter
    end

    def receiving data
      send_event('output', {
        output: data.force_encoding('utf-8'),
        category: 'stdout'
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
      Output.adapter.write envelope
    end
  end
end
