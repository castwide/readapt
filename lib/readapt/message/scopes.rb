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
              variablesReference: TOPLEVEL_BINDING.receiver.object_id,
              expensive: true
            }
          ]
        })
      end
    end
  end
end
