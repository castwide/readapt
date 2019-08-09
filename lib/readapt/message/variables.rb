# frozen_string_literal: true

module Readapt
  module Message
    class Variables < Base
      def run
        ref = arguments['variablesReference']
        frame = debugger.frame(ref)
        vars = if frame
          frame.locals
        elsif ref == TOPLEVEL_BINDING.receiver.object_id
          global_variables.map do |gv|
            Variable.new(gv, eval(gv.to_s))
          end
        else
          obj = ObjectSpace._id2ref(ref)
          if obj
            if obj.is_a?(Array)
              result = []
              obj.each_with_index do |itm, idx|
                result.push Variable.new("[#{idx}]", itm)
              end
              result
            elsif obj.is_a?(Hash)
              result = []
              obj.each_pair do |idx, itm|
                result.push Variable.new("[#{idx}]", itm)
              end
              result
            else
              result = []
              obj.instance_variables.each do |iv|
                result.push Variable.new(iv, obj.instance_variable_get(iv))
              end
              obj.class.class_variables.each do |cv|
                result.push Variable.new(cv, obj.class.class_variable_get(cv))
              end
              result
            end
          else
            []
          end
        end
        set_body({
          variables: vars.map do |var|
            {
              name: var.name,
              value: var.value,
              type: var.type,
              variablesReference: var.reference
            }
          end
        })
      end
    end
  end
end
