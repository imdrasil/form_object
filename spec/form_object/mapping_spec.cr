require "../spec_helper"

module H::Mapping
  class AddressForm < FormObject::Base(Address)
    attr :str, String, origin: :street
  end

  class ContactWithAddressForm < CF
    object :address, Address, AddressForm
  end

  class ContactWithCollectionForm < CF
    collection :addresses, Address
  end

  class ContactForm < CF
    attr :name, String
    attr :gender, String
    attr :array, Array(Int32), virtual: true
    attr :count, Int32, virtual: true
  end

  class ContactWithPathForm < CF
    path "root[contact]"

    attr :name, String
    attr :gender, String
    attr :array, Array(Int32), virtual: true
  end

  describe FormObject::Mapping do
    describe "data types" do
      describe "Array" do
        it do
          c = Factory.build_contact
          data = form_data([
            ["array[]", "1"],
            ["name", "name"],
            ["array[]", "2"]
          ])
          f = ContactForm.new(c)
          f.verify(data)
          f.array.should eq([1, 2])
        end
      end
    end

    describe ".path" do
      it "takes keys regarding defined root path" do
        c = Factory.build_contact
        data = form_data([
          ["array[]", "1"],
          ["name", "name"],
          ["array[]", "2"],

          ["root[contact][array][]", "2"],
          ["root[contact][name]", "another name"],
          ["root[contact][array][]", "3"]
        ])
        f = ContactWithPathForm.new(c)
        f.verify(data)
        f.name.should eq("another name")
        f.array.should eq([2, 3])
      end
    end

    describe ".attr" do
      describe "#attribute!" do
        it "performs nil assertion" do
          c = Factory.build_contact(name: nil)
          data = form_data([["sex", ""]])
          f = ContactForm.new(c)
          f.verify(data)

          expect_raises(FormObject::NotAssignedError) do
            f.name!
          end
        end
      end

      describe "#attribute" do
        it "returns value as is" do
          c = Factory.build_contact(name: nil)
          data = form_data([
            ["sex", ""]
          ])
          f = ContactForm.new(c)
          f.verify(data)

          f.name.should be_nil
        end
      end

      describe "#attribute=" do
        context "with String" do
          it "coerces value" do
            c = Factory.build_contact(name: nil)
            f = ContactForm.new(c)

            f.count = "2"
            f.count.should eq(2)
          end

          it "raises TypeCastError" do
            c = Factory.build_contact(name: nil)
            f = ContactForm.new(c)

            expect_raises(FormObject::TypeCastError) do
              f.count = "a"
            end
          end
        end

        context "with defined type" do
          it do
            c = Factory.build_contact(name: nil)
            f = ContactForm.new(c)

            f.count = 2
            f.count.should eq(2)
          end
        end
      end
    end

    describe ".object" do
      describe "#object!" do
        it "performs nil assertion" do
          f = ContactWithAddressForm.new(Factory.build_contact)

          expect_raises(FormObject::NotAssignedError) do
            f.address!
          end
        end
      end

      describe "#object" do
        it "returns value as is" do
          f = ContactWithAddressForm.new(Factory.build_contact)

          f.address.should be_nil
        end
      end

      describe "#object=" do
        context "with model" do
          it "wraps it into form object" do
            c = Factory.build_contact
            a = Factory.build_address

            f = ContactWithAddressForm.new(c)

            f.address = a
            f.address!.resource.should eq(a)
          end
        end

        context "with form object" do
          it do
            c = Factory.build_contact
            a = Factory.build_address
            f = ContactWithAddressForm.new(c)

            f.address = AddressForm.new(a)
            f.address!.resource.should eq(a)
          end
        end
      end

      context "without form_class" do
        pending "add"
      end

      context "with origin" do
        pending "add"
      end

      context "without populator" do
        pending "add"
      end

      context "without save" do
        pending "add"
      end
    end

    describe ".collection" do
      describe "#collection!" do
        it "returns empty array" do
          f = ContactWithCollectionForm.new(Factory.build_contact)

          f.addresses.should eq([] of AddressForm)
        end
      end

      describe "#collection" do
        it "returns value as is" do
          f = ContactWithCollectionForm.new(Factory.build_contact)

          f.addresses.should eq([] of AddressForm)
        end
      end

      describe "#collection=" do
        context "with array of model" do
          it "wraps it into array of form object" do
            c = Factory.build_contact
            a = Factory.build_address

            f = ContactWithCollectionForm.new(c)

            f.addresses = [a]
            f.addresses[0].resource.should eq(a)
          end
        end

        context "with form object array" do
          it do
            c = Factory.build_contact
            a = Factory.build_address
            f = ContactWithCollectionForm.new(c)

            f.addresses = [AddressForm.new(a)]
            f.addresses[0].resource.should eq(a)
          end
        end
      end

      describe "#add_collection" do
        it "adds given object to existing array" do
          c = Factory.build_contact
          a = Factory.build_address
          f = ContactWithCollectionForm.new(c)

          f.addresses = [AddressForm.new(a)]
          f.addresses[0].resource.should eq(a)
        end
      end

      context "without form_class" do
        it "creates form of correct class" do
          c = Factory.build_contact
          f = ContactWithCollectionForm.new(c)
          f.add_addresses(Factory.build_address)
          f.addresses[0].is_a?(AddressForm).should be_true
        end
      end

      context "with origin" do
        pending "add"
      end

      context "without populator" do
        pending "add"
      end

      context "without save" do
        pending "add"
      end
    end
  end
end
