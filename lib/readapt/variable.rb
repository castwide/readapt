# frozen_string_literal: true

module Readapt
  class Variable
    # @return [String]
    attr_reader :name

    # @param name [String, Symbol]
    # @param object [Object]
    def initialize name, object
      @name = name
      @object = object
    end

    # @return [Integer]
    def reference
      @reference ||= unstructured || object.object_id
    end

    # @return [String]
    def value
      @value ||= if object.nil?
        'nil'
      elsif show_class_for_value?
        "#{empty? ? 'Empty ' : ''}#{object.class}"
      else
        object.to_s
      end
    end

    # @return [String]
    def type
      object.class.to_s
    end

    private

    UNSTRUCTURED_TYPES = [NilClass, String, TrueClass, FalseClass, Numeric]
    private_constant :UNSTRUCTURED_TYPES

    # @return [Object]
    attr_reader :object

    # @return [Integer, nil]
    def unstructured
      0 if UNSTRUCTURED_TYPES.any? { |cls| object.is_a?(cls) } || no_references?
    end

    # @return [Boolean]
    def show_class_for_value?
      object.is_a?(Array) || object.is_a?(Hash)
    end

    def no_references?
      (object.instance_variables.empty? && object.class.class_variables.empty?) && (!enumerable? || object.empty?)
    end

    def enumerable?
      object.is_a?(Array) || object.is_a?(Hash)
    end

    def empty?
      enumerable? && object.empty?
    end
  end
end
