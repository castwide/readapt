# frozen_string_literal: true

module Readapt
  # @!method file
  #   @return [String]
  # @!method line
  #   @return [Integer]
  # @!method binding_id
  #   @return [Integer]
  # @!method initialize(file, line, binding_id)
  class Frame
    def evaluate code
      frame_binding.eval(code).inspect
    rescue Exception => e
      "[#{e.class}] #{e.message}"
    end

    def location
      Location.new(file, line)
    end

    def local_id
      binding_id
    end

    def locals
      return [] if frame_binding.nil?
      result = []
      frame_binding.local_variables.each do |sym|
        var = frame_binding.local_variable_get(sym)
        result.push Variable.new(sym, var)
      end
      if frame_binding.receiver != TOPLEVEL_BINDING.receiver
        result.push Variable.new(:self, frame_binding.receiver)
      end
      result
    end

    def local sym
      return frame_binding.receiver if sym == :self
      frame_binding.local_variable_get sym
    end

    private

    def frame_binding
      obj = ObjectSpace._id2ref(binding_id)
      raise RangeError, "Frame contains #{obj.class} instead of Binding" unless obj.is_a?(Binding)
      obj
    rescue RangeError => e
      STDERR.puts "[#{e.class}] #{e.message}"
      ObjectSpace._id2ref(nil.object_id)
    end
    NULL_FRAME = Frame.new("", 0, nil.object_id)
  end
end
