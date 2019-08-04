# frozen_string_literal: true

module Readapt
  module Message
    class ConfigurationDone < Base
      def run
        inspector.debugger.launch inspector.debugger.file
      end
    end
  end
end
