# frozen_string_literal: true

module Readapt
  module Message
    class Attach < Base
      def run
        STDERR.puts "Attaching"
        # inspector.debugger.launch inspector.debugger.file
      end
    end
  end
end
