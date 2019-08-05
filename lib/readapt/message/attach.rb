# frozen_string_literal: true

module Readapt
  module Message
    class Attach < Base
      def run
        inspector.debugger.attach Readapt.normalize_path(arguments['program'])
      end
    end
  end
end
