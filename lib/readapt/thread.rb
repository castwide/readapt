# frozen_string_literal: true

require 'ostruct'

module Readapt
  class Thread
    @@next_id = 0

    # @return [Symbol]
    attr_accessor :control

    def name
      @name ||= begin
        @@next_id += 1
        "Thread #{@@next_id}"
      end
    end

    def object
      STDERR.puts "Getting #{id}"
      ObjectSpace._id2ref(id)
    end

    # def frames
    #   @frames ||= []
    # end
  end
end
