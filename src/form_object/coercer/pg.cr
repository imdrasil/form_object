module FormObject
  class Coercer
    def coerce(value : String, str_class : String)
      case str_class
      # when /Array/
      #   to_array(value, str_class)
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
      # when /Numeric/
      #   to_numeric(value)
      else
        raise ArgumentError.new
      end
    end

    def to_numeric(value)
      value = value.strip
      raise ArgumentError.new unless value =~ /-{0,1}\d+(.\d+){0,1}/
      sign =
        if value[0] == '-'
          value = value[1..-1]
          0x4000
        else
          0i16
        end

      number = to_f(value)
      size = value.size
      weight = value.index('.') || -1
      if weight == -1
        int_part = value
        digits = integer_str_to_i16_array(int_part)
        PG::Numeric.build(digits.size.to_i16, (digits.size - 1).to_i16, sign, 0i16, digits)
      else
        int_part = value[0...weight]
        digits = integer_str_to_i16_array(int_part)
        int_digits_size = digits.size
        float_str_to_i16_array(value[(weight + 1)..-1], digits)
        PG::Numeric.build(digits.size.to_i16, (int_digits_size - 1).to_i16, sign, (value.size - weight - 1).to_i16, digits)
      end
    end

    private def integer_str_to_i16_array(value)
      array = [] of Int16
      weight = value.size
      first_part_size = weight % 4
      start_i = 0
      end_i = first_part_size == 0 ? 4 : first_part_size
      while true
        array << value[start_i...end_i].to_i16
        break if weight <= end_i
        start_i = end_i
        end_i += 4
      end
      array
    end

    private def float_str_to_i16_array(value : String, array = [] of Int16)
      weight = value.size
      start_i = 0
      end_i = 4
      while true
        array << value[start_i...end_i].ljust(4, '0').to_i16
        break if weight <= end_i
        start_i = end_i
        end_i += 4
      end
      array.delete_at(-1) if array[-1] == 0i16
      array
    end
  end
end
