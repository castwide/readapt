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
      @@next_id += 1
      @name = "Thread #{@@next_id}"
    end

    def frames
      @frames ||= []
    end

    NULL_THREAD = Thread.new(nil).freeze
  end
end
