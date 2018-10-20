module FormObject
  module Module
    include Mapping

    macro populate_module(type)
      {%
        source_mapping = type.resolve.constant("MAPPING")
        target_mapping = @type.constant("MAPPING")
      %}
      {% for key, value in source_mapping %}
        {% unless target_mapping[key] %}
          {%
            target_mapping[key] = {
              type: value[:type],
              origin: value[:origin],
              virtual: value[:virtual],
              stringified_type: value[:stringified_type],
              null: value[:null],
              array: value[:array],
              defined: value[:defined]
            }
          %}
        {% end %}
      {% end %}
    end

    macro populate_attributes
      macro included
        {% verbatim do %}
          {% unless @type.has_constant?("MAPPING") %}
            # :nodoc:
            MAPPING = {} of Symbol => NamedTuple
          {% end %}
          populate_module({{@type.ancestors[0]}})
        {% end %}

        populate_attributes
      end
    end

    macro included
      # :nodoc:
      MAPPING = {} of Symbol => NamedTuple

      populate_attributes
    end
  end
end
