require 'spec_helper'

describe CsvRowModel::Model do
  describe "instance" do
    let(:options) { {} }
    let(:instance) { BasicModel.new(nil, options) }

    describe "#child?" do
      subject { instance.child? }

      specify { expect(subject).to eql false }

      context "with a parent" do
        let(:parent_instance) { BasicModel.new }
        let(:options) { { parent:  parent_instance } }
        specify { expect(subject).to eql true }
      end
    end

    context "for ImportClass" do
      let(:source_row) { %w[a b] }
      let(:options) { { parent: parent_instance } }
      let(:instance) { BasicImportModel.new(source_row, {}) }

      let(:parent_instance) { ParentImportModel.new(source_row) }
      before do
        allow(BasicModel).to receive(:new).with(source_row, options).and_return instance
        parent_instance.append_child(source_row, options)
      end

      describe "#append_child" do
        let(:another_instance) { instance.dup }

        subject { parent_instance.append_child(source_row) }

        before do
          expect(BasicModel).to receive(:new).with(source_row, options).and_return another_instance
        end

        it "appends the child and returns it" do
          expect(subject).to eql another_instance
          expect(parent_instance.children).to eql [instance, another_instance]
        end

        context "when child is invalid" do
          before do
            another_instance.define_singleton_method(:valid?) { false }
          end

          it "doesn't append the child and returns nil" do
            expect(subject).to eql nil
            expect(parent_instance.children).to eql [instance]
          end
        end
      end

      describe "#deep_public_send" do
        context "with a parent" do
          before do
            parent_instance.define_singleton_method(:meth) { "haha" }
            instance.define_singleton_method(:meth) { "baka" }
          end

          subject { parent_instance.deep_public_send(:meth) }

          it "returns the results of calling public_send on itself and children" do
            expect(subject).to eql %w[haha baka]
          end
        end
      end
    end
  end
end