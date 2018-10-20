require "../spec_helper"

module H::Module
  module ContactName
    include FormObject::Module

    attr :name, String
  end

  module ContactGender
    include FormObject::Module

    attr :sex, String, origin: :gender
  end

  module ContactFields
    include ContactName
    include ContactGender

    attr :count, Int32, virtual: true
  end

  class ContactWithModule < CF
    include ContactFields

    attr :age, Int32?
  end

  class ContactWithDirectModule < CF
    include ContactName
  end

  class ContactWithTwoDirectModules < CF
    include ContactName
    include ContactGender
  end

  describe FormObject::Module do
    describe ".attr" do
      describe "with one module in inheritance" do
        it "parses all fields" do
          c = Factory.build_contact
          data = form_data([
            ["age", "99"],
            ["name", "name"],
            ["sex", "male"],
            ["count", "4"]
          ])
          f = ContactWithDirectModule.new(c)
          f.verify(data)

          f.name.should eq("name")
        end

        it "populates default validations" do
          c = Factory.build_contact(name: nil)
          data = form_data([["count", "4"]])
          f = ContactWithDirectModule.new(c)
          f.verify(data)

          f.errors[:name].empty?.should be_false
        end
      end

      describe "with several includes into class" do
        it "parses all fields" do
          c = Factory.build_contact
          data = form_data([
            ["age", "99"],
            ["name", "name"],
            ["sex", "male"],
            ["count", "4"]
          ])
          f = ContactWithTwoDirectModules.new(c)
          f.verify(data)

          f.name.should eq("name")
          f.sex.should eq("male")
        end

        it "populates default validations" do
          c = Factory.build_contact(name: nil)
          c.gender = nil
          data = form_data([["count", "4"]])
          f = ContactWithTwoDirectModules.new(c)
          f.verify(data)

          f.errors[:name].empty?.should be_false
          f.errors[:sex].empty?.should be_false
        end
      end

      describe "with nested modules" do
        it "parses all fields" do
          c = Factory.build_contact
          data = form_data([
            ["age", "99"],
            ["name", "name"],
            ["sex", "male"],
            ["count", "4"]
          ])
          f = ContactWithModule.new(c)
          f.verify(data)

          f.name.should eq("name")
          f.sex.should eq("male")
          f.count.should eq(4)
          f.age.should eq(99)
        end

        it "populates default validations" do
          c = Factory.build_contact(name: nil)
          c.gender = nil
          data = form_data([["age", "4"]])
          f = ContactWithModule.new(c)
          f.verify(data)

          f.errors[:name].empty?.should be_false
          f.errors[:sex].empty?.should be_false
          f.errors[:count].empty?.should be_false
        end
      end
    end
  end
end
