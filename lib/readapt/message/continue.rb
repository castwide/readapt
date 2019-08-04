# frozen_string_literal: true

module Readapt
  module Message
    class Continue < Base
      def run
        # @todo Is it possible to continue a single thread?
        set_body({
          allThreadsContinued: true
        })
        inspector.control = :continue
      end
    end
  end
end
