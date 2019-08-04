# frozen_string_literal: true

module Readapt
  class Breakpoint < Location
    attr_reader :verified

    def initialize file, line, verified = true
      super(file, line)
      @verified = verified
    end

    def enabled?
      @verified
    end
  end
end
