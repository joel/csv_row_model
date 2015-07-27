require 'spec_helper'

class Grandparent; end
module Child; end
class Parent < Grandparent
  include Child
  include CsvRowModel::DeepClassVar
end
class ClassWithFamily < Parent; end

describe CsvRowModel::DeepClassVar do
  describe "class" do
    describe "::deep_class_var" do
      let(:variable_name) { :@deep_class_var }

      before do
        [Grandparent, Parent, Child, ClassWithFamily].each do |klass|
          klass.instance_variable_set(variable_name, [klass.to_s])
        end
      end

      subject { ClassWithFamily.send(:deep_class_var, variable_name, [], :+, Child) }

      it "returns a class variable merged across ancestors until included_module" do
        expect(subject).to eql %w[Parent ClassWithFamily]
      end
    end
  end
end
