# frozen_string_literal: true

module Readapt
  module Message
    class Disconnect < Base
      def run
        Monitor.stop
        Backport.stop if inspector.debugger.launched?
      end
    end
  end
end
