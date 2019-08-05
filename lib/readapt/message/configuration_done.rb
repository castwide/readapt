# frozen_string_literal: true

module Readapt
  module Message
    class ConfigurationDone < Base
      def run
        inspector.debugger.start
      end
    end
  end
end
