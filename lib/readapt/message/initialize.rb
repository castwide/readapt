# frozen_string_literal: true

module Readapt
  module Message
    class Initialize < Base
      def run
        set_body({
          supportsConfigurationDoneRequest: true
        })
      end
    end
  end
end
