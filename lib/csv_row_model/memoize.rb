module CsvRowModel
  module Memoize
    extend ActiveSupport::Concern

    class_methods do

      protected

      # Returns a memoized variable on the class that included `included_module`
      #
      # @param variable_name [Symbol] name of the variable name memoized
      # @param default_value [Symbol] default value of the memoized variable
      # @param included_module [Module] module to search for
      # @return [Object] returns the value of the instance variable of the class that included `included_module`
      def memoized_class_included_var(variable_name, default_value, included_module)
        class_included = class_included(included_module)
        if self == class_included
          #
          # equal to: @variable_name ||= default_value
          #
          variable_name = "@#{variable_name}"
          instance_variable_get(variable_name) || instance_variable_set(variable_name, default_value)
        else
          class_included.public_send(variable_name)
        end
      end

      # Returns the class that included `included_module`, so class variables can be stored there without inheritance prpblems
      #
      # @param included_module [Module] module to search for
      # @return [Class] the class that included `included_module`
      def class_included(included_module)
        @class_included ||= {}
        @class_included[included_module] ||= begin
          inherited_ancestors = ancestors[0..(ancestors.index(included_module) - 1)]
          index = inherited_ancestors.rindex {|inherited_ancestor| inherited_ancestor.class == Class }
          inherited_ancestors[index]
        end
      end
    end

  end
end
