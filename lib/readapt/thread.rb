# frozen_string_literal: true

require 'ostruct'

module Readapt
  class Thread
    @@next_id = 0

    # @return [Symbol]
    attr_accessor :control

    def initialize
      # @@next_id += 1
      # @name = "Thread #{@@next_id}"
    end

    def name
      @name ||= begin
        @@next_id += 1
        "Thread #{@@next_id}"
      end
    end

    def frames
      @frames ||= []
    end

    # NULL_THREAD = Thread.new.freeze
  end
end
