# frozen_string_literal: true

module Readapt
  class Variable
    # @return [String]
    attr_reader :name

    # @return [Integer]
    attr_reader :reference

    def initialize name, reference
      @name = name
      @reference = reference
      object = ObjectSpace._id2ref(reference)
      @value = object.to_s
      @type = object.class.to_s
    end

    # @return [String]
    def value
      object.to_s
    end

    # @return [String]
    def type
      object.class.to_s
    end

    private

    def object
      @object ||= ObjectSpace._id2ref(reference)
    end
  end
end
