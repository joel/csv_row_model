require 'spec_helper'

describe CsvRowModel::Import::Mapper do
  describe "instance" do
    let(:source_row) { %w[a b] }
    let(:options) { {} }
    let(:instance) { ImportMapper.new(source_row, options) }

    describe "#initialize" do
      it "created the row_model" do
        expect(instance.row_model.class).to eql BasicImportModel
      end
    end

    describe "#skip?" do
      subject { instance.skip? }

      around do |example|
        expect(instance.skip?).to eql false
        example.run
        expect(instance.skip?).to eql true
      end

      it "skips when invalid" do
        instance.define_singleton_method(:valid?) { false }
      end

      it "skips when the row_model skips" do
        instance.row_model.define_singleton_method(:skip?) { true }
      end
    end

    describe "#abort?" do
      it "aborts when the row_model aborts" do
        expect(instance.abort?).to eql false
        instance.row_model.define_singleton_method(:abort?) { true }
        expect(instance.abort?).to eql true
      end
    end

    describe "::memoize" do
      before do
        instance.define_singleton_method(:_memoized_method) { Random.rand }
      end
      subject { -> { instance.memoized_method } }

      it "memoized the method" do
        expect(subject.call).to eql subject.call
      end
    end
  end
end