# frozen_string_literal: true

module Readapt
  module Message
    class SetBreakpoints < Base
      def run
        path = Readapt.normalize_path(arguments['source']['path'])
        debugger.clear_breakpoints path
        lines = []
        set_body(
          breakpoints: arguments['breakpoints'].map do |val|
            debugger.set_breakpoint path, val['line'], val['condition'], val['hitCondition']
            lines.push val['line']
            {
              verified: true, # @todo Verify
              source: arguments['source'],
              line: val['line']
            }
          end
        )
        Breakpoints.set(path, lines)
      end
    end
  end
end
