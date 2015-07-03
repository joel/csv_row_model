module CsvRowModel
  module Import
    module Mapper
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Validations
        include Base

        attr_reader :row_model

        delegate :context, :previous, :free_previous, :append_child, to: :row_model
      end

      def initialize(*args)
        @row_model = self.class.row_model_class.new(*args)
      end

      def valid?
        super && row_model.valid?
      end

      # TODO: validations...
      def skip?
        row_model.skip?
      end

      def abort?
        row_model.abort?
      end

      def attributes
        row_model.attributes
      end

      module ClassMethods
        def memoize(*method_names)
          method_names.each do |method_name|
            define_method(method_name) do
              #
              # equal to: @method_name ||= _method_name
              #
              variable_name = "@#{method_name}"
              instance_variable_get(variable_name) || instance_variable_set(variable_name, send("_#{method_name}"))
            end
          end
        end

        def row_model_class
          raise NotImplementedError
        end
      end
    end
  end
end