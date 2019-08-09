# frozen_string_literal: true

module Readapt
  module Message
    class StepOut < Base
      def run
        debugger.thread(arguments['threadId']).control = :step_out
      end
    end
  end
end
