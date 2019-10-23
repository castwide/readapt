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
      frame_binding.eval(code).inspect
    rescue Exception => e
      "[#{e.class}] #{e.message}"
    end

    def location
      @location ||= Location.new(file, line)
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
      @frame_binding ||= ObjectSpace._id2ref(binding_id)
    rescue RangeError
      @frame_binding = ObjectSpace._id2ref(nil.object_id)
    end

    NULL_FRAME = Frame.new("(nil)", 0, 0, nil.object_id)
  end
end
