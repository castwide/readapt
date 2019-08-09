# frozen_string_literal: true

module Readapt
  module Message
    class StepIn < Base
      def run
        debugger.thread(arguments['threadId']).control = :step_in
      end
    end
  end
end
