# frozen_string_literal: true

module Readapt
  class Inspector
    attr_reader :debugger
    attr_reader :frame
    attr_accessor :control

    def initialize debugger, frame
      @debugger = debugger
      @frame = frame
      @control = :pause
    end
  end
end
