# frozen_string_literal: true

module Readapt
  module Message
    class SetBreakpoints < Base
      def run
        path = Readapt.normalize_path(arguments['source']['path'])
        Monitor.breakpoints.clear path
        result = arguments['lines'].map do |l|
          # @todo Assuming breakpoints are verified
          Breakpoint.new(path, l, true)
        end
        Monitor.breakpoints.concat result
        set_body({
          breakpoints: result.map { |bp|
            {
              verified: bp.verified,
              source: arguments['source'],
              line: bp.line
            }
          }
        })
      end
    end
  end
end
