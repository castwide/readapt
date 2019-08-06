# frozen_string_literal: true

module Readapt
  module Message
    class Pause < Base
      def run
        Monitor.pause arguments['threadId']
      end
    end
  end
end
