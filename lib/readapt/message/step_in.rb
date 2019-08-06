# frozen_string_literal: true

module Readapt
  module Message
    class StepIn < Base
      def run
        # @todo Is it possible to continue a single thread?
        # inspector.control = :step_in
        debugger.thread(arguments['threadId']).control = :step_in
      end
    end
  end
end
