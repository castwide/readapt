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

    def local_id
      frame_binding.object_id
    end

    def locals
      return [] if frame_binding.nil?
      result = []
      frame_binding.local_variables.sort.each do |sym|
        var = frame_binding.local_variable_get(sym)
        result.push Variable.new(sym, var)
      end
      result.push Variable.new(:self, frame_binding.receiver)
      result
    end

    def local sym
      return frame_binding.receiver if sym == :self
      frame_binding.local_variable_get sym
    end

    NULL_FRAME = Frame.new("", 0, nil)
  end
end
