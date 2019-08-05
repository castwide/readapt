# frozen_string_literal: true

module Readapt
  module Message
    class Attach < Base
      def run
        inspector.debugger.attach arguments['program']
      end
    end
  end
end
