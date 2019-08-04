# frozen_string_literal: true

module Readapt
  module Message
    class StackTrace < Base
      @@id = 0
      def run
        # here = inspector.debugger.frames.select { |frm| frm.thread_id == arguments['threadId'] }
        here = [inspector.frame]
        STDERR.puts inspector.inspect
        set_body({
          stackFrames: here.map do |frm|
            {
              name: "#{File.basename(frm.location.file)}:#{frm.location.line}",
              source: {
                name: File.basename(frm.location.file),
                path: frm.location.file
              },
              id: frm.object_id,
              line: frm.location.line,
              column: 0
            }
          end,
          totalFrames: here.length
        })
      end
    end
  end
end
