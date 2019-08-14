# frozen_string_literal: true

module Readapt
  module Message
    class SetBreakpoints < Base
      def run
        path = Readapt.normalize_path(arguments['source']['path'])
        Breakpoints.set(path, arguments['lines'])
        set_body(
          breakpoints: arguments['lines'].map do |l|
            {
              verified: true, # @todo Verify
              source: arguments['source'],
              line: l
            }
          end
        )
      end
    end
  end
end
