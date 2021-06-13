# frozen_string_literal: true

module Readapt
  module Message
    class Initialize < Base
      def run
        set_body({
          supportsConfigurationDoneRequest: true,
          exceptionBreakpointFilters: [
            {
              filter: 'raise',
              label: 'Break on raised exceptions',
              description: 'The debugger will break when an exception is raised, regardless of whether it is subsequently rescued.',
              default: false
            }
          ]
        })
      end
    end
  end
end
