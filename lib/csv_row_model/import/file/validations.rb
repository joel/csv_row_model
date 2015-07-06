module CsvRowModel
  module Import
    class File
      module Validations
        extend ActiveSupport::Concern

        included do
          include ActiveModel::Validations
          include Validators::ValidateAttributes

          validate_attributes :csv
        end

        def abort?
          !valid? || !!current_row_model.try(:abort?)
        end

        def skip?
          !!current_row_model.try(:skip?)
        end

        protected
        def _abort?
          abort = abort?
          run_callbacks(:abort) if abort
          abort
        end

        def _skip?
          skip = skip?
          run_callbacks(:skip) if skip
          skip
        end
      end
    end
  end
end