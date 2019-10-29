# frozen_string_literal: true

module Readapt
  module Message
    class Variables < Base
      def run
        ref = arguments['variablesReference']
        frame = debugger.frame(ref)
        # @todo 1 is a magic number representing the toplevel binding (see
        #   Message::Scopes)
        vars = if ref == 1
          global_variables.map do |gv|
            Variable.new(gv, eval(gv.to_s))
          end
        else
          if frame != Frame::NULL_FRAME && !frame.nil?
            frame.locals
          else
            obj = object_reference
            result = []
            if obj.is_a?(Array)
              obj.each_with_index do |itm, idx|
                result.push Variable.new("[#{idx}]", itm)
              end
            elsif obj.is_a?(Hash)
              obj.each_pair do |idx, itm|
                result.push Variable.new("[#{idx}]", itm)
              end
            else
              obj.instance_variables.each do |iv|
                result.push Variable.new(iv, obj.instance_variable_get(iv))
              end
              obj.class.class_variables.each do |cv|
                result.push Variable.new(cv, obj.class.class_variable_get(cv))
              end
            end
            result
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

      private

      def object_reference
        ObjectSpace._id2ref(arguments['variablesReference'])
      rescue RangeError
        nil
      end
    end
  end
end
