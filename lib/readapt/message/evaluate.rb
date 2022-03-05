# frozen_string_literal: true

require 'json'

module Readapt
  module Message
    class Evaluate < Base
      def run
        ref = arguments['frameId']
        frame = debugger.frame(ref)
        expression = arguments['expression']
        result = ref ? frame.evaluate(expression) : eval(expression)
        set_body(
          result: result
        )
      end
    end
  end
end
