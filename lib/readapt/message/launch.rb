# frozen_string_literal: true

module Readapt
  module Message
    class Launch < Base
      def run
        inspector.debugger.file = Readapt.normalize_path(arguments['program'])
      end
    end
  end
end
