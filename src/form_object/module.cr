module FormObject
  # Base form object module.
  #
  # Include this in the first module that gets further included.
  #
  # ```
  # module ContactName
  #   include FormObject::Module
  #
  #   attr :name, String
  # end
  #
  # module ContactGender
  #   include FormObject::Module
  #
  #   attr :sex, String, origin: :gender
  # end
  #
  # module ContactFields
  #   include ContactName
  #   include ContactGender
  #
  #   attr :count, Int32, virtual: true
  # end
  #
  # class ContactWithModule < FormObject::Base(Contact)
  #   include ContactFields
  #
  #   attr :age, Int32?
  # end
  # ```
  #
  # Only attribute definition is supported in shared modules.
  module Module
    include Mapping

    # :nodoc:
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

    # :nodoc:
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
