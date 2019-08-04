# frozen_string_literal: true

module Readapt
  module Message
    class Next < Base
      def run
        inspector.control = :next
      end
    end
  end
end
