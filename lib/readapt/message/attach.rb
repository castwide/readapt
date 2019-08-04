# frozen_string_literal: true

module Readapt
  module Message
    class Attach < Base
      def run
        inspector.debugger.connection = :attach
      end
    end
  end
end
