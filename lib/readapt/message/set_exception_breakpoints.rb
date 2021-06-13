# frozen_string_literal: true

module Readapt
  module Message
    class SetExceptionBreakpoints < Base
      def run
        debugger.pause_on_raise = arguments['filters'] && arguments['filters'].include?('raise')
      end
    end
  end
end
