module CsvRowModel
  module Import
    # Represents a mapping between a {Import} {row_model} and your own models
    #
    # __Should implement the class method {row_model_class}__
    module Mapper
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Validations
        include Validators::ValidateAttributes

        attr_reader :row_model

        delegate :context, :previous, :free_previous, :append_child,
                 :attributes, :to_json, to: :row_model

        validates :row_model, presence: true
        validate_attributes :row_model
      end

      def initialize(*args)
        @row_model = self.class.row_model_class.new(*args)
      end

      # Safe to override.
      #
      # @return [Boolean] returns true, if this instance should be skipped
      def skip?
        !valid? || row_model.skip?
      end

      # Safe to override.
      #
      # @return [Boolean] returns true, if the entire csv file should stop reading
      def abort?
        row_model.abort?
      end

      class_methods do
        # @return [Class] returns the class that includes {Model} that the {Mapper} class maps to
        # defaults based on self.class: `FooMapper` or `Foo` => `FooRowModel` or the one set by {Mapper.maps_to}
        def row_model_class
          return @row_model_class if @row_model_class

          @row_model_class = begin
            case self.name
            when /Mapper/
              self.name.gsub(/Mapper/, 'RowModel')
            else
              "#{self.name}RowModel"
            end.constantize
          end
        end

        protected

        class AlreadyInitializedMap < StandardError;end

        # Sets the row model class that that the {Mapper} class maps to
        # @param [Class] row_model_class the class that includes {Model} that the {Mapper} class maps to
        def maps_to(row_model_class)
          raise AlreadyInitializedMap.new('should only be called once') if @row_model_class_setted
          @row_model_class_setted = true
          @row_model_class = row_model_class
        end

        # For every method name define the following:
        #
        # ```ruby
        # def method_name; @method_name ||= _method_name end
        # ```
        #
        # @param [Array<Symbol>] method_names method names to memoize
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
      end
    end
  end
end
