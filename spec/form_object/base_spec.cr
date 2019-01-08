require "../spec_helper"

module H::Base
  h = self

  class AddressForm < FormObject::Base(Address)
    attr :str, String, origin: :street
    attr :main, Bool
  end

  class ContactForm < CF
    attr :name, String
    attr :sex, String, origin: :gender
    attr :count, Int32, virtual: true
    attr :_deleted, Bool?, virtual: true

    object :address, Address, AddressForm, populator: :populate_address

    def populate_address(model, **opts)
      model || self.address = Address.new({contact_id: resource.id})
    end
  end

  class ContactWithCollectionForm < CF
    attr :name, String
    attr :sex, String, origin: :gender

    collection :addresses, Address, AddressForm, populator: :populate_address_collection

    def populate_address_collection(collection, index, **opts)
      if collection[index]?
        collection[index]
      else
        form = AddressForm.new(Address.new({contact_id: resource.id}))
        addresses << form
        form
      end
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

      it "creates nested form object" do
        c = Factory.build_contact
        a = Factory.build_address
        c.append_address a
        f = ContactForm.new(c)
        f.address!.resource.should eq(a)
      end

      it "creates collection of nested form objects" do
        c = Factory.build_contact
        a = Factory.build_address
        c.append_addresses a
        f = ContactWithCollectionForm.new(c)
        f.addresses[0].resource.should eq(a)
      end
    end

    describe ".read_query_params" do
      context "with extra field" do
        it do
          r = json_data({} of String => String, [
            ["name", "name"],
            ["sex", "male"],
            ["count", "3"],
            ["_deleted", "0"],
            ["extra_field", "1"]
          ])
          c = FormObject::Context.new
          ContactForm.read_query_params(r, c)
          c.properties.should eq({ "name" => "name", "sex" => "male", "count" => 3, "_deleted" => false })
        end
      end

      context "with missing fields" do
        it do
          r = json_data({} of String => String, [
            ["name", "name"]
          ])
          c = FormObject::Context.new
          ContactForm.read_query_params(r, c)
          c.properties.should eq({ "name" => "name" })
        end
      end

      context "with nested object" do
        it do
          r = json_data({} of String => String, [
            ["name", "name"],
            ["address[str]", "some name"],
            ["address[main]", "0"]
          ])
          c = FormObject::Context.new
          ContactForm.read_query_params(r, c)
          c.properties.should eq({ "name" => "name" })
          c.objects.size.should eq(1)
          c.objects["address"].properties.should eq({ "str" => "some name", "main" => false })
        end
      end

      context "with nested collection" do
        it do
          r = json_data({} of String => String, [
            ["name", "name"],
            ["addresses[][str]", "some name"],
            ["addresses[][main]", "0"]
          ])
          c = FormObject::Context.new
          ContactWithCollectionForm.read_query_params(r, c)
          c.properties.should eq({ "name" => "name" })
          c.collections.size.should eq(1)
          collection =  c.collections["addresses"]
          collection.size.should eq(1)
          collection[0].properties.should eq({ "str" => "some name", "main" => false })
        end

        context "with non-direct order" do
          it do
            r = json_data({} of String => String, [
              ["addresses[][str]", "name1"],
              ["addresses[][main]", "1"],
              ["name", "name"],
              ["addresses[][main]", "0"],
              ["addresses[][str]", "name2"]
            ])
            c = FormObject::Context.new
            ContactWithCollectionForm.read_query_params(r, c)
            c.properties.should eq({ "name" => "name" })
            c.collections.size.should eq(1)
            collection =  c.collections["addresses"]
            collection.size.should eq(2)
            collection[0].properties.should eq({ "str" => "name1", "main" => true })
            collection[1].properties.should eq({ "str" => "name2", "main" => false })
          end
        end
      end

      describe "inheritance" do
        it do
          r = json_data({} of String => String, [
            ["name", "name"],
            ["gender", "gender"]
          ])
          ChildContactForm.parse(r).properties.should eq({ "name" => "name", "gender" => "gender" })
        end
      end
    end

    describe ".read_url_encoded_form" do
      context "with extra field" do
        it do
          r = url_encoded_form_data([
            ["name", "name"],
            ["sex", "male"],
            ["count", "3"],
            ["_deleted", "0"],
            ["extra_field", "1"]
          ])
          c = FormObject::Context.new
          ContactForm.read_url_encoded_form(r, c)
          c.properties.should eq({ "name" => "name", "sex" => "male", "count" => 3, "_deleted" => false })
        end
      end

      context "with missing fields" do
        it do
          r = url_encoded_form_data([
            ["name", "name"]
          ])
          c = FormObject::Context.new
          ContactForm.read_url_encoded_form(r, c)
          c.properties.should eq({ "name" => "name" })
        end
      end

      context "with nested object" do
        it do
          r = url_encoded_form_data([
            ["name", "name"],
            ["address[str]", "some name"],
            ["address[main]", "0"]
          ])
          c = FormObject::Context.new
          ContactForm.read_url_encoded_form(r, c)
          c.properties.should eq({ "name" => "name" })
          c.objects.size.should eq(1)
          c.objects["address"].properties.should eq({ "str" => "some name", "main" => false })
        end
      end

      context "with nested collection" do
        it do
          r = url_encoded_form_data([
            ["name", "name"],
            ["addresses[][str]", "some name"],
            ["addresses[][main]", "0"]
          ])
          c = FormObject::Context.new
          ContactWithCollectionForm.read_url_encoded_form(r, c)
          c.properties.should eq({ "name" => "name" })
          c.collections.size.should eq(1)
          collection =  c.collections["addresses"]
          collection.size.should eq(1)
          collection[0].properties.should eq({ "str" => "some name", "main" => false })
        end

        context "with non-direct order" do
          it do
            r = url_encoded_form_data([
              ["addresses[][str]", "name1"],
              ["addresses[][main]", "1"],
              ["name", "name"],
              ["addresses[][main]", "0"],
              ["addresses[][str]", "name2"]
            ])
            c = FormObject::Context.new
            ContactWithCollectionForm.read_url_encoded_form(r, c)
            c.properties.should eq({ "name" => "name" })
            c.collections.size.should eq(1)
            collection =  c.collections["addresses"]
            collection.size.should eq(2)
            collection[0].properties.should eq({ "str" => "name1", "main" => true })
            collection[1].properties.should eq({ "str" => "name2", "main" => false })
          end
        end
      end

      describe "inheritance" do
        it do
          r = url_encoded_form_data([
            ["name", "name"],
            ["gender", "gender"]
          ])
          ChildContactForm.parse(r).properties.should eq({ "name" => "name", "gender" => "gender" })
        end
      end
    end

    describe ".read_multipart_form" do
      context "with extra field" do
        it do
          r = form_data([
            ["name", "name"],
            ["sex", "male"],
            ["count", "3"],
            ["_deleted", "0"],
            ["extra_field", "1"]
          ])
          c = FormObject::Context.new
          ContactForm.read_multipart_form(r, c)
          c.properties.should eq({ "name" => "name", "sex" => "male", "count" => 3, "_deleted" => false })
        end
      end

      context "with missing fields" do
        it do
          r = form_data([
            ["name", "name"]
          ])
          c = FormObject::Context.new
          ContactForm.read_multipart_form(r, c)
          c.properties.should eq({ "name" => "name" })
        end
      end

      context "with nested object" do
        it do
          r = form_data([
            ["name", "name"],
            ["address[str]", "some name"],
            ["address[main]", "0"]
          ])
          c = FormObject::Context.new
          ContactForm.read_multipart_form(r, c)
          c.properties.should eq({ "name" => "name" })
          c.objects.size.should eq(1)
          c.objects["address"].properties.should eq({ "str" => "some name", "main" => false })
        end
      end

      context "with nested collection" do
        it do
          r = form_data([
            ["name", "name"],
            ["addresses[][str]", "some name"],
            ["addresses[][main]", "0"]
          ])
          c = FormObject::Context.new
          ContactWithCollectionForm.read_multipart_form(r, c)
          c.properties.should eq({ "name" => "name" })
          c.collections.size.should eq(1)
          collection =  c.collections["addresses"]
          collection.size.should eq(1)
          collection[0].properties.should eq({ "str" => "some name", "main" => false })
        end

        context "with non-direct order" do
          it do
            r = form_data([
              ["addresses[][str]", "name1"],
              ["addresses[][main]", "1"],
              ["name", "name"],
              ["addresses[][main]", "0"],
              ["addresses[][str]", "name2"]
            ])
            c = FormObject::Context.new
            ContactWithCollectionForm.read_multipart_form(r, c)
            c.properties.should eq({ "name" => "name" })
            c.collections.size.should eq(1)
            collection =  c.collections["addresses"]
            collection.size.should eq(2)
            collection[0].properties.should eq({ "str" => "name1", "main" => true })
            collection[1].properties.should eq({ "str" => "name2", "main" => false })
          end
        end
      end

      describe "inheritance" do
        it do
          r = form_data([
            ["name", "name"],
            ["gender", "gender"]
          ])
          ChildContactForm.parse(r).properties.should eq({ "name" => "name", "gender" => "gender" })
        end
      end
    end

    describe ".read_json_form" do
      context "with extra field" do
        it do
          r = json_data({
            "name" => "name",
            "sex" => "male",
            "count" => 3,
            "_deleted" => false,
            "extra_field" => 1
          })
          c = FormObject::Context.new
          ContactForm.read_json_form(r, c)
          c.properties.should eq({ "name" => "name", "sex" => "male", "count" => 3, "_deleted" => false })
        end
      end

      context "with missing fields" do
        it do
          r = json_data({
            "name" => "name"
          })
          c = FormObject::Context.new
          ContactForm.read_json_form(r, c)
          c.properties.should eq({ "name" => "name" })
        end
      end

      context "with nested object" do
        it do
          r = json_data({
            "name" => "name",
            "address" => {
              "str" => "some name",
              "main" => false
            }
          })
          c = FormObject::Context.new
          ContactForm.read_json_form(r, c)
          c.properties.should eq({ "name" => "name" })
          c.objects.size.should eq(1)
          c.objects["address"].properties.should eq({ "str" => "some name", "main" => false })
        end
      end

      context "with nested collection" do
        it do
          r = json_data({
            "name" => "name",
            "addresses" => [{ "str" => "some name", "main" => false }]
          })
          c = FormObject::Context.new
          ContactWithCollectionForm.read_json_form(r, c)
          c.properties.should eq({ "name" => "name" })
          c.collections.size.should eq(1)
          collection =  c.collections["addresses"]
          collection.size.should eq(1)
          collection[0].properties.should eq({ "str" => "some name", "main" => false })
        end

        context "with multiple records" do
          it do
            r = json_data({
              "addresses" => [
                { "str" => "name1", "main" => true },
                { "str" => "name2", "main" => false }
              ],
              "name" => "name",
            })
            c = FormObject::Context.new
            ContactWithCollectionForm.read_json_form(r, c)
            c.properties.should eq({ "name" => "name" })
            c.collections.size.should eq(1)
            collection =  c.collections["addresses"]
            collection.size.should eq(2)
            collection[0].properties.should eq({ "str" => "name1", "main" => true })
            collection[1].properties.should eq({ "str" => "name2", "main" => false })
          end
        end

        it "parses non-root object" do
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

          c = ContactForNonRootJSONForm.parse(r)
          c.properties.should eq({ "name" => "name", "sex" => "male", "count" => 3, "_deleted" => false })
        end
      end

      describe "inheritance" do
        it do
          r = json_data({
            "name" => "name",
            "gender" => "gender"
          })
          ChildContactForm.parse(r).properties.should eq({ "name" => "name", "gender" => "gender" })
        end
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

      describe "nested object" do
        it "assigns attributes for nested object" do
          c = Factory.build_contact
          f = ContactForm.new(c)

          f.verify(form_data([
            ["name", "name"],
            ["sex", "male"],
            ["count", "1"],
            ["address[str]", "some specific street"]
          ]))
          f.address!.str.should eq("some specific street")
        end
      end

      describe "nested collection" do
        it "assigns attributes to nested collection" do
          c = Factory.build_contact
          f = ContactWithCollectionForm.new(c)

          f.verify(form_data([
            ["name", "name"],
            ["sex", "male"],
            ["count", "1"],
            ["addresses[][str]", "some specific street"]
          ]))
          f.addresses[0].str.should eq("some specific street")
        end
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

      it "reverifies" do
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
        f.save.should be_true

        c.new_record?.should be_false
      end

      it "saves nested object" do
        # NOTE: parent object should exist
        c = Factory.create_contact
        r = form_data([
          ["name", "name"],
          ["count", "2"],
          ["address[str]", "street 1"],
          ["address[main]", "0"]
        ])
        f = ContactForm.new(c)
        f.verify(r)
        f.save

        c.address_reload.should_not be_nil
      end

      it "saves nested collection" do
        c = Factory.create_contact
        r = form_data([
          ["name", "name"],
          ["count", "2"],
          ["addresses[][str]", "street 1"],
          ["addresses[][main]", "0"]
        ])
        f = ContactWithCollectionForm.new(c)
        f.verify(r)
        f.save

        c.addresses_reload.empty?.should be_false
        c.addresses[0].new_record?.should be_false
      end

      context "with invalid nested object" do
        pending "add"


      # NOTE: invalid nested objects will be ignored
      # it "saves nested object" do
      #   c = Factory.build_contact
      #   r = form_data([
      #     ["name", "name"],
      #     ["count", "2"],
      #     ["address[str]", "some name"],
      #     ["address[main]", "0"]
      #   ])
      #   f = ContactForm.new(c)
      #   f.verify(r)
      #   f.save

      #   puts f.inspect
      #   puts Address.all.count
      #   c.address_reload
      #   c.address.should_not be_nil
      # end
      end
    end
  end
end
