require "../spec_helper"

describe FormObject::ContextCollection do
  described_class = FormObject::ContextCollection

  describe "#object_for" do
    context "when given field has been already added" do
      it do
        c = described_class.new
        first_context = c.object_for("field1")
        c.object_for("field2")
        second_context = c.object_for("field1")
        first_context.should_not eq(second_context)
        c.size.should eq(2)
      end
    end
  end
end
