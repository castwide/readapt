# frozen_string_literal: true

module Readapt
  class Location
    attr_reader :file
    attr_reader :line

    def initialize file, line
      @file = file
      @line = line
    end

    def match? other
      return false unless other.is_a?(Location)
      file == other.file && line == other.line
    end

    def self.called caller
      file_line = caller.match(/^(.*?):([\d]+)/)
      raise ArgumentError, "Invalid caller syntax #{caller}" if file_line.nil?
      new file_line[1], file_line[2].to_i
    end
  end
end
