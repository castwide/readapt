# frozen_string_literal: true

module Readapt
  module Message
    class Base
      # @return [Hash]
      attr_reader :arguments

      # @return [Inspector]
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
