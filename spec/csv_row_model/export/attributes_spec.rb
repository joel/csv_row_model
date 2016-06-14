require 'spec_helper'

describe CsvRowModel::Export::Attributes do
  let(:source_model) { Model.new('a', 'b') }
  let(:instance) { row_model_class.new(source_model) }

  describe 'instance' do
    let(:row_model_class) { BasicExportModel }

    describe "#cells" do
      subject { instance.cells }

      it "returns a hash of cells mapped to their column_name" do
        expect(subject.keys).to eql row_model_class.column_names
        expect(subject.values.map(&:class)).to eql [CsvRowModel::Export::Cell] * 2
      end
    end

    describe "#formatted_attributes" do
      subject { instance.formatted_attributes }

      it "returns the attributes hash" do
        expect(row_model_class).to receive(:format_cell).exactly(2).times.and_call_original
        expect(subject).to eql(string1: 'a', string2: 'b')
      end
    end

    describe "#formatted_attribute" do
      it_behaves_like "cell_attribute", :formatted_attribute, :value, string1: "a"
    end

    describe "#source_attribute" do
      it_behaves_like "cell_attribute", :source_attribute, :source_value, string1: "a"
    end
  end

  describe 'class' do
    let(:row_model_class) do
      Class.new do
        include CsvRowModel::Model
        include CsvRowModel::Export
      end
    end

    describe "::column" do
      it_behaves_like "column_method", CsvRowModel::Export, string1: "a", string2: "b"
    end

    describe "::define_attribute_method" do
      it_behaves_like "define_attribute_method"
    end
  end
end
