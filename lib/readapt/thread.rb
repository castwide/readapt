# frozen_string_literal: true

require 'ostruct'

module Readapt
  class Thread
    # @return [Symbol]
    attr_accessor :control

    # @return [String]
    def name
      @name ||= "Thread #{id}"
    end

    # # @return [Object]
    def object
      ObjectSpace._id2ref(thread_object_id)
    end
  end
end
