# frozen_string_literal: true

module Readapt
  module Message
    class SetBreakpoints < Base
      def run
        path = Readapt.normalize_path(arguments['source']['path'])
        Breakpoints.set(path, arguments['lines'])
        set_body(
          breakpoints: arguments['breakpoints'].map do |val|
            debugger.set_breakpoint arguments['source'], val['line'], val['condition']
            {
              verified: true, # @todo Verify
              source: arguments['source'],
              line: val['line']
            }
          end
        )
      end
    end
  end
end
