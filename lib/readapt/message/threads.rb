# frozen_string_literal: true

module Readapt
  module Message
    class Threads < Base
      def run
        set_body({
          threads: debugger.stopped.map do |thr|
            {
              id: thr.id,
              name: thr.name
            }
          end
        })
      end
    end
  end
end
