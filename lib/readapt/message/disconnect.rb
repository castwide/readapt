# frozen_string_literal: true

module Readapt
  module Message
    class Disconnect < Base
      def run
        Backport.stop
      end
    end
  end
end
