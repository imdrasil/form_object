require "../spec_helper"

module H::Mapping
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

        context "with JSON::PullParser" do
          pending "" do
          end
        end

        context "with HTTP::FormData::Part" do
          pending "" do
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
  end
end
