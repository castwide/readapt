require 'observer'

module Readapt
  class Breakpoints
    include Observable

    def initialize
      @sources = {}
      @concatting = false
    end

    # @return [Array<String>]
    def sources
      @sources.keys
    end

    # @param breakpoint [Breakpoint]
    # @return [void]
    def add breakpoint
      @sources[breakpoint.file] ||= []
      @sources[breakpoint.file].push breakpoint
      changed
      notify_observers unless @concatting
    end

    # @param breakpoints [Array<Breakpoint>]
    # @return [void]
    def concat breakpoints
      @concatting = true
      breakpoints.each { |bp| add bp }
      @concatting = false
      notify_observers
    end

    # @param file [String]
    # @return [void]
    def clear file
      @sources.delete file
      changed
      notify_observers
    end

    # @param file [String]
    # @return [Array<Breakpoint>]
    def for file
      @sources[file] || []
    end

    # @return [Array<Breakpoint>]
    def all
      @sources.values.flatten
    end

    def empty?
      @sources.empty?
    end
  end
end
