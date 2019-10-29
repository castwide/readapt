# frozen_string_literal: true

module Readapt
  module Message
    class StackTrace < Base
      @@file_hash = {}

      def run
        frames = debugger.thread(arguments['threadId']).frames
        set_body({
          stackFrames: frames.map do |frm|
            {
              name: frame_code(frm.location.file, frm.location.line),
              source: {
                name: frm.location.file ? File.basename(frm.location.file) : nil,
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

      private

      def read_file file
        @@file_hash[file] ||= File.read(file)
      end

      def frame_code file, line
        read_file(file).lines[line - 1].strip
      end
    end
  end
end
