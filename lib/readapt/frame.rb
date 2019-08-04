# frozen_string_literal: true

module Readapt
  class Frame
    attr_reader :thread_id

    attr_reader :location

    def initialize location, binding_id, thread_id
      @location = location
      @binding = ObjectSpace._id2ref(binding_id)
      @thread_id = thread_id
    end

    def local_id
      @binding.object_id
    end

    def locals
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

    def variables
      result = []
      @binding.local_variables.each do |sym|
        var = @binding.local_variable_get(sym)
        result.push Variable.new(sym, var)
      end
      if @binding.receiver != TOPLEVEL_BINDING.receiver
        @binding.instance_variables.each do |sym|
          var = @binding.receiver.instance_variable_get(sym)
          result.push Variable.new(sym, var)
        end
        @binding.class.class_variables.each do |sym|
          var = @binding.receiver.class.class_variable_get(sym)
          result.push Variable.new(sym, var)
        end
      end
      result
    end

    def local sym
      return @binding.receiver if sym == :self
      @binding.local_variable_get sym
    end

    def globals
      global_variables
    end

    def global sym
      global sym
    end

    def evaluate code
      @binding.eval code
    end
  end
end
