module Readapt
  module Output
    def receiving data
      send_event('output', {
        output: data,
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
      write envelope
    end
  end
end
