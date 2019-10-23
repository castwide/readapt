# frozen_string_literal: true

module Readapt
  # @!method file
  #   @return [String]
  # @!method line
  #   @return [Integer]
  # @!method method_id
  #   @return [Symbol]
  # @!method binding_id
  #   @return [Integer]
  # @!method initialize(file, line, method_id, binding_id)
  class Frame
    def evaluate code
      @binding.eval(code).inspect
    rescue Exception => e
      "[#{e.class}] #{e.message}"
    end

    def location
      @location ||= Location.new(file, line)
    end

    def binding
      ObjectSpace._id2ref(binding_id)
    end

    def local_id
      @binding.object_id
    end

    def locals
      return [] if @binding.nil?
      result = []
      @binding.local_variables.each do |sym|
        var = @binding.local_variable_get(sym)
        result.push Variable.new(sym, var)
      end
      if @binding.receiver != TOPLEVEL_BINDING.receiver
        result.push Variable.new(:self, @binding.receiver)
      end
      result
    end

    def local sym
      return @binding.receiver if sym == :self
      @binding.local_variable_get sym
    end

    NULL_FRAME = Frame.new(nil, nil.object_id)
  end
end
