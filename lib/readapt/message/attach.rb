# frozen_string_literal: true

module Readapt
  module Message
    class Attach < Base
      def run
        raise RuntimeError, 'Attaching to running process is not supported yet'
      end
    end
  end
end
