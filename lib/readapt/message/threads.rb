# frozen_string_literal: true

module Readapt
  module Message
    class Threads < Base
      def run
        num = 0
        if inspector.frame.nil?
          set_body({
            threads: []
          })
        else
          set_body({
            # threads: inspector.debugger.threads.map do |thr|
            #   num += 1
            #   {
            #     id: thr,
            #     name: "Thread #{num}"
            #   }
            # end
            threads: [
              {
                id: inspector.frame.thread_id,
                name: "Thread 1"
              }
            ]
          })
        end
      end
    end
  end
end
