require "../spec_helper"

class ContactForm < FormObject::Base(Contact)
  mapping(
    name: String,
    sex: { type: String, origin: :gender },
    count: { type: Int32, virtual: true },
    _deleted: { type: Bool?, virtual: true }
  )

  object :address, Address do
    mapping(
      str: { type: String, origin: :street }
    )
  end
end

module H
  def self.valid_data
    form_data do |builder|
      builder.field("name", "zxczx")
      builder.field("sex", "male")
      builder.field("count", "23")
      builder.field("address[str]", "some str")
    end
  end

  def self.invalid_data
    form_data do |builder|
      builder.field("name", "")
      builder.field("sex", "male")
      builder.field("count", "23")
      builder.field("address[str]", "some str")
    end
  end
end

describe FormObject::Base do
  describe ".new" do
    it do
      c = Factory.build_contact
      f = ContactForm.new(c)
      f.resource.should eq(c)
    end
  end

  describe "#verify" do
    it "assigned parsed data to form object attributes" do
      c = Factory.build_contact
      f = ContactForm.new(c)
      f.verify(H.valid_data)
      f.name.should eq("zxczx")
      f.sex.should eq("male")
      f.count.should eq(23)
    end

    it "doesn't sync with the resource" do
      c = Factory.build_contact
      f = ContactForm.new(c)
      f.verify(H.valid_data)
      c.name.should eq("Deepthi")
      c.gender.should eq("female")
    end

    context "when data is valid" do
      it do
        c = Factory.build_contact
        f = ContactForm.new(c)
        f.verify(H.valid_data).should be_true
      end
    end

    context "when data is invalid" do
      it do
        c = Factory.build_contact
        f = ContactForm.new(c)
        f.verify(H.invalid_data).should be_false
      end
    end
  end

  describe "#valid?" do

  end

  describe "#invalid?" do

  end

  describe "#save" do
    context "with block" do

    end
  end

  describe "#validate!" do

  end
end
