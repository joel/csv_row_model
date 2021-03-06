require 'spec_helper'

describe BooleanFormatValidator do
  let(:klass) do
    Class.new do
      include ActiveWarnings
      attr_accessor :string1
      warnings do
        validates :string1, boolean_format: true
      end

      def self.name; "TestClass" end
    end
  end
  let(:instance) { klass.new }
  subject { instance.safe? }

  it_behaves_like "validated_types"

  context "proper Boolean" do
    before { instance.string1 = "t" }

    it "is valid" do
      expect(subject).to eql true
    end
  end
end