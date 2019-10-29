# frozen_string_literal: true

module Readapt
  module Message
    class Scopes < Base
      def run
        frame = debugger.frame(arguments['frameId'])
        set_body({
          scopes: [
            {
              name: 'Local',
              variablesReference: frame.local_id,
              expensive: false
            },
            {
              name: 'Global',
              # @todo 1 is a magic number representing the toplevel binding
              variablesReference: 1,
              expensive: true
            }
          ]
        })
      end
    end
  end
end
