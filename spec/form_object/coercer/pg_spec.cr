require "../../spec_helper"
require "../../../src/form_object/coercer/pg"

# TODO: add 2 environments to test without this
describe FormObject::Coercer do
  coercer = FormObject::Coercer.new

  describe "#coerce" do
    it { coercer.coerce("1", "Numeric?").is_a?(PG::Numeric).should be_true }
  end

  describe "#to_numeric" do
    it { coercer.to_numeric("1").to_s.should eq("1") }
    it { coercer.to_numeric("12345").to_s.should eq("12345") }
    it { coercer.to_numeric("9999").to_s.should eq("9999") }
    it { coercer.to_numeric("-1").to_s.should eq("-1") }
    it { coercer.to_numeric("1.12345").to_s.should eq("1.12345") }
    it { coercer.to_numeric("-1.12345").to_s.should eq("-1.12345") }

    # NOTE: some cases from the will/crystal-pg

    it { coercer.to_numeric("0").to_s.should eq("0") }
    it { coercer.to_numeric("0.0").to_s.should eq("0.0") }
    it { coercer.to_numeric("1.30").to_s.should eq("1.30") }
    it { coercer.to_numeric("-0.00009").to_s.should eq("-0.00009") }
    it { coercer.to_numeric("-0.00000009").to_s.should eq("-0.00000009") }
    it { coercer.to_numeric("50093").to_s.should eq("50093") }
    it { coercer.to_numeric("500000093").to_s.should eq("500000093") }
    it { coercer.to_numeric("0.0000006000000").to_s.should eq("0.0000006000000") }
    it { coercer.to_numeric("0.3").to_s.should eq("0.3") }
    it { coercer.to_numeric("0.03").to_s.should eq("0.03") }
    it { coercer.to_numeric("0.003").to_s.should eq("0.003") }
    it { coercer.to_numeric("0.000300003").to_s.should eq("0.000300003") }
  end
end
