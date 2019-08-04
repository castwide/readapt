# frozen_string_literal: true

module Readapt
  module Message
    class Base
      attr_reader :arguments
      attr_reader :inspector

      def initialize arguments, inspector
        @arguments = arguments
        @inspector = inspector
      end

      def run; end

      def body
        @body ||= {}
      end

      def set_body hash
        @body = hash
      end

      def self.run arguments, inspector
        new(arguments, inspector).run
      end
    end
  end
end

