require "../spec_helper"

describe FormObject::Coercer do
  coercer = FormObject::Coercer.new
  local_time_zone = Time::Location.local

  describe "#coerce" do
    it { coercer.coerce("1", "String?").is_a?(String).should be_true }
    it { coercer.coerce("1", "Int16").is_a?(Int16).should be_true }
    it { coercer.coerce("1", "Int32").is_a?(Int32).should be_true }
    it { coercer.coerce("1", "Int64").is_a?(Int64).should be_true }
    it { coercer.coerce("1", "Float64").is_a?(Float64).should be_true }
    it { coercer.coerce("1", "Float32?").class.should eq(Float32) }
    it { coercer.coerce("1", "Bool").is_a?(Bool).should be_true }
    it { coercer.coerce("1", "JSON::Any?").is_a?(JSON::Any).should be_true }
    it { coercer.coerce("2010-12-10", "Time?").is_a?(Time).should be_true }
    # it { coercer.coerce(%(["1"]), "Array(String)").class.should eq(Array(String)) }
    it { coercer.coerce("asd".as(String?), "String?").class.should eq(String) }
    it { coercer.coerce(nil.as(String?), "String?").class.should eq(Nil) }
  end

  describe "#to_time" do
    it { coercer.to_time("2010-10-10").should eq(Time.local(2010, 10, 10)) }
    it { coercer.to_time("2010-10-10 20:10:10").should eq(Time.local(2010, 10, 10, 20, 10, 10)) }

    it "ignores given time zone" do
      coercer.to_time("2010-10-10 20:10:10 +01:00").should eq(Time.local(2010, 10, 10, 20, 10, 10, location: local_time_zone))
    end
  end

  describe "#to_b" do
    it { coercer.to_b("1").should be_true }
    it { coercer.to_b("true").should be_true }
    it { coercer.to_b("t").should be_true }
    it { coercer.to_b("0").should be_false }
    it { coercer.to_b("").should be_false }
  end

  # describe "#to_array" do
  #   it { coercer.to_array("[1]", "Array(Int32)").should eq([1]) }
  #   it { coercer.to_array("[1]", "Array(Int16)").should eq([1i16]) }
  #   it { coercer.to_array("[1]", "Array(Int64)").should eq([1i64]) }
  #   it { coercer.to_array(%(["1"]), "Array(String)").should eq(["1"]) }
  #   it { coercer.to_array("[1.0]", "Array(Float32)").should eq([1f32]) }
  #   it { coercer.to_array("[1.0]", "Array(Float64)").should eq([1.0]) }
  # end
end
