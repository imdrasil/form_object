module FormObject
  class Coercer
    def coerce(value : String, str_class : String)
      case str_class
      when /Array/
        to_array(value, str_class)
      when /String/
        to_s(value)
      when /Int16/
        to_i16(value)
      when /Int64/
        to_i64(value)
      when /Int/
        to_i(value)
      when /Float32/
        to_f32(value)
      when /Float/
        to_f(value)
      when /Bool/
        to_b(value)
      when /JSON/
        to_json(value)
      when /Time/
        to_time(value)
      else
        raise ArgumentError.new
      end
    end

    def coerce(value : Nil, str_class : String)
      nil
    end

    def to_pr32(value : String)
      to_i(value)
    end

    def to_pr64(value : String)
      to_i64(value)
    end

    def to_s(value : String)
      value
    end

    def to_i16(value : String)
      value.to_i16
    end

    def to_i64(value : String)
      value.to_i64
    end

    def to_i(value : String)
      value.to_i
    end

    def to_f(value : String)
      value.to_f
    end

    def to_f32(value : String)
      value.to_f32
    end

    def to_b(value : String)
      value == "true" || value == "1" || value == "t"
    end

    def to_json(value : String)
      JSON.parse(value)
    end

    def to_time(value : String)
      format = value =~ / / ? "%F %T" : "%F"
      Time.parse(value, format, FormObject.local_time_zone)
    end

    # Converts single string array.
    #
    # ```
    # coercer.to_array("[1]", "Array(Int32)") # [1]
    # ```
    def to_array(value : String, str_class : String)
      array = to_json(value).as_a
      case str_class
      when /Int32/
        array.map(&.as_i)
      when /Float32/
        array.map(&.as_f32)
      when /Float64/
        array.map(&.as_f)
      when /Int16/
        array.map(&.as_i.to_i16)
      when /Int64/
        array.map(&.as_i64)
      when /String/
        array.map(&.as_s)
      else
        raise ArgumentError.new
      end
    end
  end
end
