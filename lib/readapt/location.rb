# frozen_string_literal: true

module Readapt
  # A simple file/line reference.
  #
  class Location
    # @return [String]
    attr_reader :file

    # @return [Integer]
    attr_reader :line

    # @param file [String]
    # @param line [Integer]
    def initialize file, line
      @file = file
      @line = line
    end

    def match? other
      return false unless other.is_a?(Location)
      file == other.file && line == other.line
    end
  end
end
