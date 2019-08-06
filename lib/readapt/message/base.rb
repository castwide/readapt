# frozen_string_literal: true

module Readapt
  module Message
    class Base
      # @return [Hash]
      attr_reader :arguments

      # @return [Debugger]
      attr_reader :debugger

      def initialize arguments, debugger
        @arguments = arguments
        @debugger = debugger
      end

      def run; end

      def body
        @body ||= {}
      end

      def set_body hash
        @body = hash
      end

      def self.run arguments, debugger
        new(arguments, debugger).run
      end
    end
  end
end
