# frozen_string_literal: true

require 'ostruct'

module Readapt
  class Thread
    @@next_id = 0

    # @return [Symbol]
    attr_accessor :control

    # @return [String]
    def name
      @name ||= begin
        @@next_id += 1
        "Thread #{@@next_id}"
      end
    end

    # @return [Object]
    def object
      ObjectSpace._id2ref(id)
    end
  end
end
