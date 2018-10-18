require "../spec_helper"

module H::Mapping
  alias CF = FormObject::Base(Contact)
  class ContactForm < CF
    mapping(
      name: String,
      gender: String,
      array: { type: Array(Int32), virtual: true }
    )
  end

  class ContactWithPathForm < CF
    mapping({
      name: String,
      gender: String,
      array: { type: Array(Int32), virtual: true }
    }, "root[contact]")
  end
end

describe FormObject::Mapping do
  describe "data types" do
    describe "Array" do
      it do
        c = Factory.build_contact
        data = form_data do |builder|
          builder.field("array[]", "1")
          builder.field("name", "name")
          builder.field("array[]", "2")
        end
        f = H::Mapping::ContactForm.new(c)
        f.verify(data)
        f.array.should eq([1, 2])
      end
    end
  end

  describe "mapping" do
    describe "custom path" do
      it "parses keys correctly" do
        c = Factory.build_contact
        data = form_data do |builder|
          builder.field("array[]", "1")
          builder.field("name", "name")
          builder.field("array[]", "2")

          builder.field("root[contact][array][]", "2")
          builder.field("root[contact][name]", "another name")
          builder.field("root[contact][array][]", "3")
        end
        f = H::Mapping::ContactWithPathForm.new(c)
        f.verify(data)
        f.name.should eq("another name")
        f.array.should eq([2, 3])
      end
    end
  end
end
