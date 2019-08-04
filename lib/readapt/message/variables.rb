# frozen_string_literal: true

module Readapt
  module Message
    class Variables < Base
      def run
        ref = arguments['variablesReference'].to_i
        # frame = inspector.debugger.frames.find { |frm| frm.local_id == ref }
        frame = (inspector.frame.local_id == ref ? inspector.frame : nil)
        vars = if frame
          frame.locals
        elsif ref == TOPLEVEL_BINDING.receiver.object_id
          global_variables.map do |gv|
            Variable.new(gv, eval(gv.to_s).object_id)
          end
        else
          obj = ObjectSpace._id2ref(ref)
          if obj
            obj.instance_variables.map do |iv|
              Variable.new(iv, obj.instance_variable_get(iv).object_id)
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
