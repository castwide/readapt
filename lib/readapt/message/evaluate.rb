# frozen_string_literal: true

require 'json'

module Readapt
  module Message
    class Evaluate < Base
      def run
        ref = arguments['frameId']
        frame = debugger.frame(ref)
        result = frame.evaluate(arguments['expression'])
        set_body(
          result: result
        )
      end
    end
  end
end
