module Readapt
  class Breakpoint
    attr_reader :source
    attr_reader :line
    attr_reader :condition

    def initialize source, line, condition
      @source = source
      @line = line
      @condition = condition
    end
  end
end
