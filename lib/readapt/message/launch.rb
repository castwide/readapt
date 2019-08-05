# frozen_string_literal: true

module Readapt
  module Message
    class Launch < Base
      def run
        inspector.debugger.launch arguments
      end
    end
  end
end
