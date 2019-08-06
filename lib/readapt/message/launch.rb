# frozen_string_literal: true

module Readapt
  module Message
    class Launch < Base
      def run
        inspector.debugger.config arguments, :launch
      end
    end
  end
end
