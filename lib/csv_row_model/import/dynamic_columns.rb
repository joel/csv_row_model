require 'csv_row_model/import/dynamic_column_cell'

module CsvRowModel
  module Import
    module DynamicColumns
      extend ActiveSupport::Concern

      included do
        self.dynamic_column_names.each { |*args| define_dynamic_attribute_method(*args) }
      end

      def cells
        @dynamic_column_cells ||= super.merge(array_to_block_hash(self.class.dynamic_column_names) do |column_name|
          DynamicColumnCell.new(column_name, dynamic_column_source_headers, dynamic_column_source_cells, self)
        end)
      end

      # @return [Hash] a map of `column_name => original_attribute(column_name)`
      def original_attributes
        super.merge(array_to_block_hash(self.class.dynamic_column_names) { |column_name| original_attribute(column_name) })
      end

      # @return [Array] dynamic_column headers
      def dynamic_column_source_headers
        self.class.dynamic_columns? ? source_header[self.class.columns.size..-1] : []
      end

      # @return [Array] dynamic_column row data
      def dynamic_column_source_cells
        self.class.dynamic_columns? ? source_row[self.class.columns.size..-1] : []
      end

      class_methods do
        # Safe to override. Method applied to each dynamic_column attribute
        #
        # @param cells [Array] Array of values
        # @param column_name [Symbol] Dynamic column name
        def format_dynamic_column_cells(cells, column_name, column_index, context)
          cells
        end

        protected

        # See {Model#dynamic_column}
        def dynamic_column(column_name, options={})
          super
          define_dynamic_attribute_method(column_name)
        end

        # Define default attribute method for a column
        # @param column_name [Symbol] the cell's column_name
        def define_dynamic_attribute_method(column_name)
          define_method(column_name) { original_attribute(column_name) }
          define_method(singular_dynamic_attribute_method_name(column_name)) { |value, source_header| value }
        end
      end
    end
  end
end
