# frozen_string_literal: true

module Readapt
  module Message
    class Disconnect < Base
      def run
        Monitor.stop
        Backport.stop if inspector.debugger.connection == :launch
      end
    end
  end
end
