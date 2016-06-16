require 'spec_helper'

describe CsvRowModel::Import::Attributes do
  let(:row_model_class) { BasicImportModel }
  let(:source_row)         { %w[1.01 b] }
  let(:instance)           { row_model_class.new(source_row) }

  describe "instance" do
    describe "#cell_objects" do
      subject { instance.cell_objects }

      it "returns a hash of cells mapped to their column_name" do
        expect(subject.keys).to eql row_model_class.column_names
        expect(subject.values.map(&:class)).to eql [CsvRowModel::Import::Cell] * 2
      end

      context "invalid and invalid csv_string_model" do
        let(:row_model_class) do
          Class.new(BasicImportModel) do
            validates :string1, presence: true
            csv_string_model { validates :string2, presence: true }
          end
        end
        let(:source_row) { [] }

        it "passes the csv_string_model.errors to _cells_objects" do
          expect(instance).to receive(:_cell_objects).with(no_args).once.and_call_original # for csv_string_model
          expect(instance).to receive(:_cell_objects).once do |errors|
            expect(errors.messages).to eql(string2: ["can't be blank"])
            {} # return empty hash to keep calling API
          end
          subject
        end

        it "returns the cells with the right attributes" do
          values = subject.values
          expect(values.map(&:column_name)).to eql %i[string1 string2]
          expect(values.map(&:source_value)).to eql [nil, nil]
          expect(values.map(&:csv_string_model_errors)).to eql [[], ["can't be blank"]]
        end
      end
    end

    describe "#original_attributes" do
      subject { instance.original_attributes }

      it "returns the attributes hash" do
        # 2 attributes * (1 for csv_string_model + 1 for original_attributes)
        expect(row_model_class).to receive(:format_cell).exactly(4).times.and_call_original
        expect(subject).to eql(string1: '1.01', string2: 'b')
      end
    end

    describe "#original_attribute" do
      it_behaves_like "cell_object_attribute", :original_attribute, :value, string1: "1.01"
    end

    describe "#default_changes" do
      subject { instance.default_changes }

      let(:row_model_class) do
        Class.new(BasicImportModel) do
          merge_options :string1, default: 123
          def self.format_cell(*args); nil end
        end
      end

      it "sets the default" do
        expect(subject).to eql(string1: [nil, 123])
      end
    end
  end

  describe "class" do
    let(:row_model_class) do
      Class.new do
        include CsvRowModel::Model
        include CsvRowModel::Import
      end
    end

    describe ":column" do
      it_behaves_like "column_method", CsvRowModel::Import, string1: "1.01", string2: "b"
    end

    describe "::merge_options" do
      subject { row_model_class.send(:merge_options, :waka, type: Integer, validate_type: true) }

      before { row_model_class.send(:column, :waka, original_options) }
      let(:original_options) { {} }

      it "adds validations" do
        expect(row_model_class).to_not receive(:define_method)
        expect(row_model_class.csv_string_model_class).to receive(:add_type_validation).once.and_call_original
        subject
      end

      context "with original_options has validate_type" do
        let(:original_options) { { type: Integer, validate_type: true } }

        it "doesn't add validations" do
          expect(row_model_class).to_not receive(:define_method)
          expect(row_model_class.csv_string_model_class).to_not receive(:add_type_validation)

          subject
        end
      end
    end

    describe "::define_attribute_method" do
      subject { row_model_class.send(:define_attribute_method, :waka) }
      before { expect(row_model_class.csv_string_model_class).to receive(:add_type_validation).with(:waka, nil).once }

      it "makes an attribute that calls original_attribute" do
        subject
        expect(instance).to receive(:original_attribute).with(:waka).and_return("tested")
        expect(instance.waka).to eql "tested"
      end

      context "with another validation added" do
        before { expect(row_model_class.csv_string_model_class).to receive(:add_type_validation).with(:waka2, nil).once }
        it_behaves_like "define_attribute_method"
      end
    end
  end
end
