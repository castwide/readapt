# frozen_string_literal: true

module Readapt
  module Message
    class StackTrace < Base
      def run
        frames = debugger.thread(arguments['threadId']).frames
        set_body({
          stackFrames: frames.map do |frm|
            {
              name: "#{frm.method_id}",
              source: {
                name: File.basename(frm.location.file),
                path: frm.location.file
              },
              id: frm.local_id,
              line: frm.location.line,
              column: 0
            }
          end,
          totalFrames: frames.length
        })
      end
    end
  end
end
