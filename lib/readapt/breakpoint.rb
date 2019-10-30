module Readapt
  class Breakpoint
    attr_reader :source
    attr_reader :line
    attr_reader :condition
    attr_reader :hit_condition
    attr_writer :hit_cursor

    def initialize source, line, condition, hit_condition
      @source = source
      @line = line
      @condition = condition
      @hit_condition = hit_condition
    end

    def hit_cursor
      @hit_cursor ||= 0
    end
  end
end
