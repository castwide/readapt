# frozen_string_literal: true

module Readapt
  module Message
    class Continue < Base
      def run
        thread = debugger.thread(arguments['threadId'])
        thread.control = :continue
        set_body({})
      end
    end
  end
end
