# frozen_string_literal: true

module Readapt
  class Frame
    attr_reader :location

    def initialize location, binding_id
      @location = location
      @binding = ObjectSpace._id2ref(binding_id)
    end

    def evaluate code
      @binding.eval(code).inspect
    rescue Exception => e
      "[#{e.class}] #{e.message}"
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
