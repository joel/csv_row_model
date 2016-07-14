require 'spec_helper'

describe CsvRowModel::Import::File do

  let(:file_path) { basic_1_row_path }
  let(:model_class) { BasicImportModel }
  let(:instance) { described_class.new file_path, model_class, 'some_context' => true }

  describe "#context" do
    it "symbolizes the context" do
      expect(instance.context[:some_context]).to eql true
    end
  end

  describe "#reset" do
    subject { instance.reset }

    context "at the end of the file" do
      before { while instance.next; end }

      it "resets and starts at the first row" do
        subject
        expect(instance.index).to eql -1
        expect(instance.line_number).to eql 0
        expect(instance.current_row_model).to eql nil
        expect(instance.next.source_row).to eql %w[lang1 lang2]
      end
    end
  end

  describe "#next" do
    let(:file_path) { basic_5_rows_path }
    subject { instance.next }

    context "when passing a context" do
      subject { instance.next('another_context' => true) }
      it "merges contexts" do
        expect(subject.context).to eql OpenStruct.new(some_context: true, another_context: true)
      end

      it "symbolizes the context in an OpenStruct" do
        expect(subject.context[:another_context]).to eql true
      end
    end

    it "gets the rows until the end of file" do
      row_model = nil
      (0..4).each do |index|
        previous_row_model = row_model
        row_model = instance.next
        expect(row_model.class).to eql model_class

        expect(row_model.source_row).to eql %W[firsts#{index} seconds#{index}]

        expect(row_model.previous.try(:source_row)).to eql previous_row_model.try(:source_row)
        expect(row_model.index).to eql index
        # header means +1, starts at 1 means +1 too--- 1 + 1 = 2
        expect(row_model.line_number).to eql index + 2
        expect(row_model.context).to eql OpenStruct.new(some_context: true)
      end

      3.times do
        expect(instance.next).to eql nil
        expect(instance.end_of_file?).to eql true
      end
    end

    context "with children" do
      let(:file_path) { parent_6_rows_path }
      let(:model_class) { ParentImportModel }

      it "gets the rows until the end of file" do
        (0..1).each do |index|
          row_model = instance.next
          expect(row_model.class).to eql model_class
          expect(row_model.source_row).to eql %W[firsts#{index} seconds#{index}]

          children = row_model.children
          expect(children.map(&:source_row)).to eql children.map.with_index {|c, index| [nil, "seconds#{index}"]  }
        end
        3.times do
          expect(instance.next).to eql nil
          expect(instance.end_of_file?).to eql true
        end
      end
    end

    context "file_model" do
      let(:file_path) { file_model_1_row_path }
      let(:instance) { described_class.new file_path, FileImportModel }

      it "works" do
        expect(subject.source_row).to eql(['value 1', 'value 2'])
        3.times do
          expect(instance.next).to eql nil
          expect(instance.end_of_file?).to eql true
        end
      end
    end

    context "with badly formatted file" do
      let(:file_path) { syntax_bad_quotes_5_rows_path }

      it "gets headers and returns invalid row" do
        row = instance.next
        expect(row).to be_valid
        expect(row.source_row).to eql ["string1", "string2"]

        invalid_row = instance.next
        expect(invalid_row).to be_invalid
        expect(invalid_row.errors.full_messages).to eql ["Csv has Missing or stray quote in line 3."]
        expect(invalid_row.source_row).to eql []

        row = instance.next
        expect(row).to be_valid
        expect(row.source_row).to eql ["lang1", "lang2"]

        expect(instance.next).to be_invalid
        expect(instance.next).to be_invalid
        expect(instance.next).to be_nil
      end
    end
  end

  describe "#end_of_file?" do
    subject { instance.end_of_file? }

    it "returns false" do
      expect(subject).to eql false
    end

    context "in the middle of file (last row)" do
      before { instance.next }

      it "returns false" do
        expect(subject).to eql false
      end
    end

    context "at the end of file" do
      before { instance.next; instance.next }

      it "returns true" do
        expect(subject).to eql true
      end
    end
  end

  describe "#each" do
    subject { instance.each }

    context "with abort" do
      before { instance.define_singleton_method(:abort?) { true } }
      it "never yields and call callbacks" do
        expect(instance).to receive(:run_callbacks).with(:abort).once
        expect { subject.next }.to raise_error(StopIteration)
      end
    end

    context "with abort on third row_model (abort on valid? ChildImport)" do
      let(:file_path) { basic_5_rows_path }
      let(:model_class) do
        Class.new(BasicImportModel) do
          def abort?; source_row.last.ends_with? "2" end
          def self.name; "BasicImportModelWithAbort" end
        end
      end

      it "yields twice and call callbacks" do
        allow(instance).to receive(:run_callbacks).with(anything).and_call_original
        expect(instance).to receive(:run_callbacks).with(:abort).and_call_original.once

        subject.next
        subject.next
        expect { subject.next }.to raise_error(StopIteration)
      end
    end

    context "with skips on even rows" do
      let(:file_path) { basic_5_rows_path }
      let(:model_class) do
        Class.new(BasicImportModel) do
          def skip?; source_row.last.last.to_i % 2 == 1 end
          def self.name; "BasicImportModelWithSkip" end
        end
      end

      it "skips twice" do
        allow(instance).to receive(:run_callbacks).with(anything).and_call_original
        expect(instance).to receive(:run_callbacks).with(:skip).and_call_original.twice

        subject.next
        subject.next
        subject.next
        expect { subject.next }.to raise_error(StopIteration)
      end
    end
  end

  describe "#valid?" do
    subject { instance.valid? }

    it "defaults to true" do
      expect(subject).to eql true
    end

    context "bad file path" do
      let(:file_path) { "abc" }

      it "has header to be an empty array" do
        expect(subject).to eql false
        expect(instance.errors.full_messages).to eql ["Csv No such file or directory @ rb_sysopen - abc"]
      end
    end
  end

  describe "#safe?" do
    subject { instance.safe? }

    it "defaults to true" do
      expect(subject).to eql true
    end

    context "bad header" do
      let(:file_path) { bad_header_1_row_path }

      it "has header to be an empty array" do
        expect(subject).to eql false
        expect(instance.headers).to eql []
        expect(instance.warnings.full_messages).to eql ["Csv has header with Unclosed quoted field on line 1."]
      end
    end
  end

  describe "abort?" do
    subject { instance.abort? }

    context "when valid?" do
      before do
        expect(instance).to receive(:valid?).and_return(true)
      end

      context "when current_row_model is nil" do
        before do
          expect(instance).to receive(:current_row_model).and_return(nil)
        end

        it "returns false" do
          expect(subject).to eql false
        end
      end
    end
  end

  describe "skip?" do
    subject { instance.skip? }

    context "when current_row_model is nil" do
      before do
        expect(instance).to receive(:current_row_model).and_return(nil)
      end

      it "returns false" do
        expect(subject).to eql false
      end
    end
  end
end
