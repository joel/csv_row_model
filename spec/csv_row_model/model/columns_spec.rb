require 'spec_helper'

describe CsvRowModel::Model::Columns do
  describe "instance" do
    let(:options) { {} }
    let(:instance) { BasicRowModel.new(options) }

    before do
      instance.define_singleton_method(:string1) { "haha" }
      instance.define_singleton_method(:string2) { "baka" }
    end

    describe "#attributes" do
      subject { instance.attributes }

      it "returns the map of column_name => public_send(column_name)" do
        expect(instance.attributes).to eql( string1: "haha", string2: "baka" )
      end
    end

    describe "#to_json" do
      it "returns the attributes json" do
        expect(instance.to_json).to eql(instance.attributes.to_json)
      end
    end
  end

  describe "class" do
    let(:klass) { BasicRowModel }

    describe "::column_names" do
      subject { klass.column_names }
      specify { expect(subject).to eql %i[string1 string2] }
    end

    describe "::format_header" do
      let(:header) { 'user_name' }
      subject { BasicRowModel.format_header(header) }

      it "returns the header" do
        expect(subject).to eql header
      end
    end

    describe "::headers" do
      let(:headers) { [:string1, 'String 2'] }
      subject { BasicRowModel.headers }

      it "returns an array with header column names" do
        expect(subject).to eql headers
      end
    end

    context "with custom class" do
      let(:klass) { Class.new { include CsvRowModel::Model } }

      describe "::options" do
        let(:options) { { type: Integer, validate_type: true } }
        before { klass.send(:column, :blah, options) }

        subject { klass.options(:blah) }

        it "returns the options for the column" do
          expect(subject).to eql options
        end
      end

      describe "::column" do
        context "with invalid option" do
          subject { klass.send(:column, :blah, invalid_option: true) }

          it "raises error" do
            expect { subject }.to raise_error(ArgumentError)
          end
        end
      end

      describe "::merge_options" do
        before { klass.send(:column, :blah, type: Integer) }
        subject { klass.send(:merge_options, :blah, default: 1) }

        it "merges the option" do
          expect { subject }.to change {
            klass.options(:blah)
          }.from(type: Integer).to(type: Integer, default: 1)
        end

        context "with child class class" do
          let(:child_class) { Class.new(klass) }

          subject do
            klass.send(:merge_options, :blah, default: 1)
            child_class.send(:merge_options, :blah, header: "Blah")
          end


          it "passes merged option to child, but not to parent" do
            expect(klass.options(:blah)).to eql(type: Integer)
            expect(child_class.options(:blah)).to eql(type: Integer)

            subject

            expect(klass.options(:blah)).to eql(type: Integer, default: 1)
            expect(child_class.options(:blah)).to eql(type: Integer, default: 1, header: "Blah")
          end
        end
      end
    end
  end
end
