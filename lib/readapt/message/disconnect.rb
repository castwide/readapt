# frozen_string_literal: true

module Readapt
  module Message
    class Disconnect < Base
      def run
        # The message only sets an empty body to acknowledge that the request
        # was received. The adapter handles the actual disconnection process.
        set_body({})
      end
    end
  end
end
