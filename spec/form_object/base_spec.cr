require "../spec_helper"

module H::Base
  h = self
  class ContactForm < CF
    attr :name, String
    attr :sex, String, origin: :gender
    attr :count, Int32, virtual: true
    attr :_deleted, Bool?, virtual: true

    object :address, Address do
      # attr :str, String, origin: :street
    end
  end

  class ContactWithValidationForm < CF
    attr :count, Int32, virtual: true

    validates_numericality :count, greater_than: 2
  end

  class ContactWithVirtualRealField < CF
    attr :name, String
    attr :gender, String, virtual: true
  end

  class ContactForNonRootJSONForm < CF
    json_path %w(contact data)

    attr :name, String
    attr :sex, String, origin: :gender
    attr :count, Int32, virtual: true
    attr :_deleted, Bool?, virtual: true
  end

  class ParentContactForm < CF
    attr :name, String
  end

  class ChildContactForm < ParentContactForm
    attr :gender, String
  end

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

  describe FormObject::Base do
    describe ".new" do
      it do
        c = Factory.build_contact
        f = ContactForm.new(c)
        f.resource.should eq(c)
      end

      it "assigns model attributes" do
        c = Factory.build_contact
        f = ContactForm.new(c)

        f.name.should eq(c.name)
      end

      it "assigns model attributes using given origin" do
        c = Factory.build_contact
        f = ContactForm.new(c)

        f.sex.should eq(c.gender)
      end

      it "ignores form virtual attributes" do
        c = Factory.build_contact
        f = ContactWithVirtualRealField.new(c)

        f.gender.should be_nil
      end
    end

    describe "#sync" do
      it "assigns all non-virtual attributes to resource" do
        c = Factory.build_contact
        f = ContactWithVirtualRealField.new(c)
        f.gender = "male"
        f.name = "test"
        f.sync

        c.gender.should eq("female")
        c.name.should eq("test")
      end

      it "assigns values using given origin method" do
        c = Factory.build_contact
        f = ContactForm.new(c)

        f.sex = "male"
        f.sync

        c.gender.should eq("male")
      end
    end

    describe "#verify" do
      it "assigned parsed data to form object attributes" do
        c = Factory.build_contact
        f = ContactForm.new(c)
        f.verify(h.valid_data)
        f.name.should eq("zxczx")
        f.sex.should eq("male")
        f.count.should eq(23)
      end

      it "doesn't sync with the resource" do
        c = Factory.build_contact
        f = ContactForm.new(c)
        f.verify(h.valid_data)
        c.name.should eq("Deepthi")
        c.gender.should eq("female")
      end

      context "when data is valid" do
        it do
          c = Factory.build_contact
          f = ContactForm.new(c)
          f.verify(h.valid_data).should be_true
        end
      end

      context "when data is invalid" do
        it do
          c = Factory.build_contact
          f = ContactForm.new(c)
          f.verify(h.invalid_data).should be_false
        end
      end

      context "with url encoded form" do
        it do
          c = Factory.build_contact
          f = ContactForm.new(c)
          r = url_encoded_form_data([
            ["name", "name"],
            ["sex", "male"],
            ["count", "3"],
            ["_deleted", "0"]
          ])

          f.verify(r)
          f.name.should eq("name")
          f.sex.should eq("male")
          f.count.should eq(3)
          f._deleted.should be_false
        end
      end

      context "with query parameters" do
        it do
          c = Factory.build_contact
          f = ContactForm.new(c)
          r = json_data({} of String => String, [
            ["name", "name"],
            ["sex", "male"],
            ["count", "3"],
            ["_deleted", "0"]
          ])

          f.verify(r)
          f.name.should eq("name")
          f.sex.should eq("male")
          f.count.should eq(3)
          f._deleted.should be_false
        end
      end

      context "with json" do
        it do
          c = Factory.build_contact
          f = ContactForm.new(c)
          r = json_data({
            name: "name",
            sex: "male",
            count: 3,
            _deleted: false
          })

          f.verify(r)
          f.name.should eq("name")
          f.sex.should eq("male")
          f.count.should eq(3)
          f._deleted.should be_false
        end

        it "parses non-root object" do
          c = Factory.build_contact
          f = ContactForNonRootJSONForm.new(c)
          r = json_data({
            links: {} of String => String,
            contact: {
              links: %w(asd),
              data: {
                name: "name",
                sex: "male",
                count: 3,
                _deleted: false
              }
            },
            address: {
              str: "asd"
            }
          })

          f.verify(r)
          f.name.should eq("name")
          f.sex.should eq("male")
          f.count.should eq(3)
          f._deleted.should be_false
        end

        it "ignores extra fields" do
          c = Factory.build_contact
          f = ContactForm.new(c)
          r = json_data({
            name: "name",
            second_name: "Arsen",
            sex: "male",
            count: 3,
            _deleted: false
          })

          f.verify(r)
          f.name.should eq("name")
          f.sex.should eq("male")
          f.count.should eq(3)
          f._deleted.should be_false
        end
      end

      describe "inheritance" do
        it do
          c = Factory.build_contact
          f = ChildContactForm.new(c)
          data = form_data([["name", "name"], %w(gender gender)])
          f.verify(data)

          f.gender.should eq("gender")
          f.name.should eq("name")
        end
      end
    end

    describe "#valid?" do
      context "with invalid data" do
        it do
          c = Factory.build_contact
          f = ContactWithValidationForm.new(c)
          f.verify(form_data([["count", "2"]]))

          f.valid?.should be_false
        end
      end

      context "with valid data" do
        it do
          c = Factory.build_contact
          f = ContactWithValidationForm.new(c)
          f.verify(form_data([["count", "3"]]))

          f.valid?.should be_true
        end
      end

      it "reverifies data" do
        c = Factory.build_contact
        f = ContactWithValidationForm.new(c)
        f.verify(form_data([["count", "2"]]))
        f.count = "3"

        f.valid?.should be_true
      end
    end

    describe "#invalid?" do
      context "with invalid data" do
        it do
          c = Factory.build_contact
          f = ContactWithValidationForm.new(c)
          f.verify(form_data([["count", "2"]]))

          f.invalid?.should be_true
        end
      end

      context "with valid data" do
        it do
          c = Factory.build_contact
          f = ContactWithValidationForm.new(c)
          f.verify(form_data([["count", "3"]]))

          f.invalid?.should be_false
        end
      end

      it "doesn't perform validation from scratch" do
        c = Factory.build_contact
        f = ContactWithValidationForm.new(c)
        f.verify(form_data([["count", "2"]]))
        f.count = "3"

        f.invalid?.should be_true
      end
    end

    describe "#save" do
      it "persists object" do
        c = Factory.build_contact
        f = ContactForm.new(c)

        f.verify(h.valid_data)
        f.save

        c.new_record?.should be_false
      end

      it "persists invalid form object" do
        c = Factory.build_contact
        f = ContactForm.new(c)
        data = form_data([["sex", "male"]])
        f.verify(data)
        f.save

        c.new_record?.should be_false
      end
    end
  end
end
