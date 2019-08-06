# frozen_string_literal: true

module Readapt
  module Message
    class Attach < Base
      def run
        inspector.debugger.config arguments, :attach
      end
    end
  end
end
