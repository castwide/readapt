module Readapt
  module References
    module_function

    @variable_reference_map = {}
    @reference_variable_map = {}
    @reference_id = 1000

    def clear
      @variable_reference_map.clear
      @reference_variable_map.clear
      @reference_id = 1000
    end

    def identify object
      return @variable_reference_map[object] if @variable_reference_map.has_key?(object)
      @reference_id += 1
      @variable_reference_map[object] = @reference_id
      @reference_variable_map[@reference_id] = object
      @reference_id
    end

    def get id
      @reference_variable_map[id]
    end
  end
end
