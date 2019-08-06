# frozen_string_literal: true

require 'ostruct'

module Readapt
  class Thread
    @@next_id = 0

    # @return [Integer]
    attr_reader :id

    # @return [String]
    attr_reader :name

    # @return [Symbol]
    attr_accessor :control

    def initialize id
      @id = id
      @name = "Thread #{@@next_id}"
      @@next_id += 1
    end

    def frames
      @frames ||= []
    end

    class NullThread < Thread
      def initialize
        @id = 0
        @name = 'Null Thread'
        @frames = [].freeze
      end
    end
    private_constant :NullThread

    NULL_THREAD = NullThread.new
  end
end
