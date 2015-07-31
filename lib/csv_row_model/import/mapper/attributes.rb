module CsvRowModel
  module Import
    module Mapper
      module Attributes
        extend ActiveSupport::Concern

        included do
          include DeepClassVar
        end

        protected

        # add errors from row_model and remove each dependent attribute from errors if it's row_model_dependencies
        # are in the errors
        def filter_errors
          using_warnings? ? row_model.using_warnings { _filter_errors } : _filter_errors
        end

        def _filter_errors
          row_model.valid?
          self.class.attribute_names.each do |attribute_name|
            next unless errors.messages[attribute_name] &&
              row_model.errors.messages.slice(*self.class.options(attribute_name)[:dependencies]).present?
            errors.delete attribute_name
          end

          errors.messages.reverse_merge!(row_model.errors.messages)
        end

        # @param [Symbol] attribute_name the attribute to check
        # @return [Boolean] if the dependencies are valid
        def valid_dependencies?(attribute_name)
          row_model.valid? || (row_model.errors.keys & self.class.options(attribute_name)[:dependencies]).empty?
        end

        # equal to: @method_name ||= yield
        # @param [Symbol] method_name method_name in description
        # @return [Object] the memoized result
        def memoize(method_name)
          variable_name = "@#{method_name}"
          instance_variable_get(variable_name) || instance_variable_set(variable_name, yield)
        end

        class_methods do
          # @return [Array<Symbol>] attribute names for the Mapper
          def attribute_names
            attributes.keys
          end

          # @return [Hash] map of `attribute_name => [options, block]`
          def attributes
            deep_class_var :@_mapper_attributes, {}, :merge, CsvRowModel::Import::Mapper::Attributes
          end

          # @param [Symbol] attribute_name name of attribute to find option
          # @return [Hash] options for the attribute_name
          def options(attribute_name)
            attributes[attribute_name].first
          end

          # @param [Symbol] attribute_name name of attribute to find block
          # @return [Proc, Lambda] block called for attribute
          def block(attribute_name)
            attributes[attribute_name].last
          end

          protected
          def _attributes
            @_mapper_attributes ||= {}
          end

          # Adds column to the row model
          #
          # @param [Symbol] attribute_name name of attribute to add
          # @param [Proc] block to calculate the attribute
          # @param options [Hash]
          # @option options [Hash] :memoize whether to memoize the attribute (default: true)
          # @option options [Hash] :dependencies the dependcies it has with the underlying row_model (default: [])
          def attribute(attribute_name, options={}, &block)
            default_options = { memoize: true, dependencies: [] }
            invalid_options = options.keys - default_options.keys
            raise ArgumentError.new("Invalid option(s): #{invalid_options}") if invalid_options.present?

            options = options.reverse_merge(default_options)

            _attributes.merge!(attribute_name.to_sym => [options, block])
            define_attribute_method(attribute_name)
          end

          # Define the attribute_method
          # @param [Symbol] attribute_name name of attribute to add
          def define_attribute_method(attribute_name)
            define_method("__#{attribute_name}", &block(attribute_name))

            define_method(attribute_name) do
              return unless valid_dependencies?(attribute_name)
              self.class.options(attribute_name)[:memoize] ?
                memoize(attribute_name) { public_send("__#{attribute_name}") } :
                public_send("__#{attribute_name}")
            end
          end
        end
      end
    end
  end
end