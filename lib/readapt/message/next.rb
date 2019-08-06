# frozen_string_literal: true

module Readapt
  module Message
    class Next < Base
      def run
        thread = debugger.thread(arguments['threadId'])
        thread.control = :next
      end
    end
  end
end
