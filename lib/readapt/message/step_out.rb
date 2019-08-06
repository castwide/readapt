# frozen_string_literal: true

module Readapt
  module Message
    class StepOut < Base
      def run
        # @todo Is it possible to continue a single thread?
        # inspector.control = :step_out
        debugger.thread(arguments['threadId']).control = :step_out
      end
    end
  end
end
