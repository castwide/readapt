# frozen_string_literal: true

module Readapt
  module Message
    class Disconnect < Base
      def run
        # HACK: Wait a moment to make sure the output is flushed
        # @todo Find a better way
        sleep 1
        debugger.disconnect
      end
    end
  end
end
