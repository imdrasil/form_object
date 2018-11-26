require "string_scanner"

module FormObject
  module Mapping
    # Specifies path to the root of defined object.
    #
    # *value* - array of exact json keys.
    #
    # ```
    # class AdditionalInfoForm < FormObject::Base(AdditionalInfo)
    #   json_path %w(additionalInfo data)
    #
    #   # ...
    # end
    # ```
    macro json_path(value)
      # :nodoc:
      JSON_PATH = {{value}}

      private def self.match_json_path?(depth : Int)
        depth + 1 == JSON_PATH.size
      end

      private def self.current_json_key(depth)
        JSON_PATH[depth + 1]
      end
    end

    # Specifies the root name for the form data or URL parameters.
    #
    # *value* - string representation of root name; if it is not specified all fields will
    # be retrieved from the root scope.
    #
    # ```
    # class AdditionalInfoForm < FormObject::Base(AdditionalInfo)
    #   path "additional_info[data]"
    #
    #   # ...
    # end
    # ```
    macro path(value)
      private def self.match_root(scanner)
        root = Regex.new(Regex.escape("{{value.id}}"))
        return if scanner.scan(root).nil?
        1
      end
    end

    # Specifies attribute being parsed from a given request.
    #
    # Options:
    # * *name* - form object attribute name
    # * *type* - attribute type; to define nilable field use `Type?` notation
    # * *origin* - related model attribute name (by default it is *name*)
    # * *virtual* - marks attribute as virtual - it will be retrieved and validated but no synchronized with model
    # (`false` by default)
    #
    # ```
    # class ContactForm < FormObject::Base(Contact)
    #   attr :name, String
    #   attr :sex, String, origin: :gender
    #   attr :count, Int32, virtual: true
    #   attr :_deleted, Bool?, virtual: true
    # end
    # ```
    #
    # Any defined field of form object is defined as nilable. For a non-nil field `#attribute` method
    # performs `#not_nil!` check.
    #
    # Defines next methods for field with name `attribute`:
    #
    # * `#attribute!` - getter with `not_nil!` check for non-nil field
    # * `#attribute` - getter without `not_nil!` check
    # * `#append_attribute(String)` - coerces given value and adds to attribute (if it is an array)
    # * `#attribute=(Type)` - setter
    # * `#attribute=(String)` - coerces given value and sets to attribute
    macro attr(name, type, origin = nil, virtual = false)
      {%
        options = {
          type: type,
          origin: origin || name,
          virtual: virtual,
          stringified_type: type.stringify,
          null: false,
          array: false,
          defined: false,
          nested: false,
          save: true,
          populator: nil
        }
        if options[:type].is_a?(Generic)
          type_name = options[:type].name.resolve
          type_vars = options[:type].type_vars
          if type_name == Union && type_vars[1].resolve == Nil
            options[:null] = true
          elsif type_name == Array
            options[:array] = true
          else
            raise "Unions are not supported"
          end
          options[:base_type] = type_vars[0].resolve
        else
          options[:base_type] = options[:type].resolve
        end

        MAPPING[name] = options
      %}

      @{{name.id}} : {{options[:type]}}{{"?".id unless options[:null]}}

      def {{name.id}}
        @{{name.id}}
      end

      def {{name.id}}!
        @{{name.id}}{{".not_nil!".id unless options[:null]}}
      rescue e : Exception
        raise FormObject::NotAssignedError.new({{name.id.stringify}})
      end

      setter :{{name.id}}

      def {{name.id}}=(value : String)
        @{{name.id}} = self.class.coerce_{{name.id}}(value).as({{options[:type].id}})
      end
    end

    # Specifies nested object form being parsed from a given request.
    #
    # Options:
    # * *name* - nested form object name
    # * *klass* - nested resource type
    # * *form_class* - form object class for a resource; (by default is `"#{klass.id}Form".id`)
    # * *origin* - related model relation name (by default is *name*)
    # * *save* - whether related model should be persisted (by default is `true`)
    # * *populator* - method name that will be used for object population.
    #
    # ```
    # class ContactForm < FormObject::Base(Contact)
    #   object :address, Address, populator: :populate_address
    #
    #   def populate_address(model, **opts)
    #     model || Address.new
    #   end
    # end
    # ```
    #
    # Any defined nested object of form object is defined as nilable.
    #
    # Populator method is called for the object with following named tuple: `{model: ModelForm?, context: FormObject::Context}.
    # Populator should return `ModelForm` object - this is required.
    #
    # > In the code snippet above described default populator that is generated if no populator is given.
    #
    # Defines next methods for field with name `attribute`:
    #
    # * `#object!` - getter with `not_nil!` check
    # * `#object` - getter without `not_nil!` check
    # * `#object=(Model)` - wraps given model in `ModelForm`
    # * `#object=(ModelForm)` - setter
    macro object(name, klass, form_class = nil, origin = nil, save = true, populator = nil)
      {% form_class = "#{klass.id}Form".id if form_class == nil %}

      {%
        options = {
          type: form_class,
          origin: origin || name,
          virtual: true,
          stringified_type: form_class.stringify,
          null: true,
          array: false,
          defined: false,
          base_type: klass,
          nested: true,
          save: save,
          populator: populator
        }

        MAPPING[name] = options
      %}

      @{{name.id}} : {{options[:type]}}?

      def {{name.id}}
        @{{name.id}}
      end

      def {{name.id}}!
        @{{name.id}}.not_nil!
      rescue e : Exception
        raise FormObject::NotAssignedError.new({{name.id.stringify}})
      end

      setter :{{name.id}}

      def {{name.id}}=(value : {{klass}})
        @{{name.id}} = {{form_class}}.new(value)
      end
    end

    # Specifies relation collection being parsed from a given request.
    #
    # Options:
    # * *name* - nested form object name
    # * *klass* - nested resource type
    # * *form_class* - form object class for a resource; (by default is `"#{klass.id}Form".id`)
    # * *origin* - related model relation name (by default is *name*)
    # * *save* - whether related model should be persisted (by default is `true`)
    # * *populator* - method name that will be used for object population.
    #
    # ```
    # class ContactForm < FormObject::Base(Contact)
    #   collection :addresses, Address, populator: :populate_address
    #
    #   def populate_address_collection(collection, index, **opts)
    #     if collection[index]?
    #       collection[index]
    #     else
    #       form = AddressForm.new(Address.new({contact_id: resource.id}))
    #       addresses << form
    #       form
    #     end
    #   end
    # end
    # ```
    #
    # Populator method is called for an object with following named tuple: `{collection: Array(ModelForm), context: FormObject::Context, index: Int32}.
    # Populator should return `ModelForm` object - this is required.
    #
    # Defines next methods for field with name `attribute`:
    #
    # * `#collection!` - same as `#collection`
    # * `#collection` - getter without `not_nil!` check
    # * `#collection=(Array(Model))` - wraps given model in `Array(ModelForm)`
    # * `#collection=(Array(ModelForm))` - setter
    # * `#add_collection(Model)` - adds given model to collection wrapping it into form object
    macro collection(name, klass, form_class = nil, origin = nil, save = true, populator = nil)
      {% form_class = "#{klass.id}Form".id if form_class == nil %}

      {%
        options = {
          type: form_class,
          origin: origin || name,
          virtual: true,
          stringified_type: form_class.stringify,
          null: false,
          array: true,
          defined: false,
          base_type: klass,
          nested: true,
          save: save,
          populator: populator
        }

        MAPPING[name] = options
      %}

      @{{name.id}} : Array({{form_class}}) = [] of {{form_class}}

      def {{name.id}}
        @{{name.id}}
      end

      def {{name.id}}!
        @{{name.id}}
      end

      setter :{{name.id}}

      def {{name.id}}=(value : Array({{klass}}))
        @{{name.id}}.clear
        value.each { |v| @{{name.id}} << {{form_class}}.new(v) }
      end

      def add_{{name.id}}(value : {{klass}})
        @{{name.id}} << {{form_class}}.new(value)
      end
    end

    # :nodoc:
    macro mapping_finished_hook
      {% mapping = @type.constant("MAPPING") %}

      {% for name, options in mapping %}
        {% unless options[:null] || options[:defined] %}
          {% options[:defined] = true %}
          validates_presence :{{name.id}}
        {% end %}
      {% end %}

      {% if @type.superclass && @type.superclass.type_vars.empty? && @type.superclass.has_constant?("MAPPING") %}
        {% for key, value in @type.superclass.constant("MAPPING") %}
          {% mapping[key] = value unless mapping[key] %}
        {% end %}
      {% end %}

      {% unless @type.abstract? %}
        def initialize(@resource)
          {% for key, value in mapping %}
            {% if value[:nested] %}
              value = @resource.{{value[:origin].id}}
              {% if value[:array] %}
                value.each { |object| @{{key.id}} << {{value[:type]}}.new(object) }
              {% else %}
                @{{key.id}} = {{value[:type]}}.new(value) if value
              {% end %}
            {% elsif !value[:virtual] %}
              @{{key.id}} = @resource.{{value[:origin].id}}
            {% end %}
          {% end %}
        end

        # :nodoc:
        def sync(ignore_nested = false)
          {% for field, value in mapping %}
            {% unless value[:virtual] %}
              resource.{{value[:origin].id}} = {{field.id}}!
            {% end %}
          {% end %}
        end

        def persist_nested
          {% for field, value in mapping %}
            {% if value[:nested] && value[:save] %}
              {{field.id}}.{{(value[:array] ? "each" : "try").id}}(&.save)
            {% end %}
          {% end %}
        end

        # :nodoc:
        def assign_fields(context : FormObject::Context)
          context.each_field do |field, value|
            case field
            {% for key, value in mapping %}
              {% unless value[:nested] %}
              when {{key.id.stringify}}
                self.{{key.id}} = value.as({{value[:type].id}})
              {% end %}
            {% end %}
            end
          end

          context.each_object do |field, context|
            begin
              case field
                {% for key, value in mapping %}
                  {% if value[:nested] && !value[:array] %}
                  {% _key = key.id.stringify %}
                  when {{_key}}
                    __{{key.id}}_populator(context).assign_fields(context)
                  {% end %}
                {% end %}
              else
              end
            rescue e : FormObject::SkipException
            end
          end


          context.each_collection do |field, context_collection|
            case field
              {% for key, value in mapping %}
                {% if value[:nested] && value[:array] %}
                when {{key.id.stringify}}
                  i = 0
                  context_collection.each_context do |context|
                    begin
                      __{{key.id}}_populator(context, i).assign_fields(context)
                    rescue e : FormObject::SkipException
                    ensure
                      i += 1
                    end
                  end
                {% end %}
              {% end %}
            else
            end
          end
        end

        # :nodoc:
        def self.parse_string_parameter(key : String, value, context)
          scanner = StringScanner.new(key)
          depth = match_root(scanner)
          return if depth.nil?
          parse_string_parameter(scanner, depth, value, context)
        end

        # :nodoc:
        def self.parse_string_parameter(scanner : StringScanner, depth, value, context)
          field = read_field(scanner, depth)
          case field
          {% for key, value in mapping %}
            {% _key = key.id.stringify %}
            when {{_key}}
            {% if value[:array] %}
              return unless read_array_suffix(scanner)
              {% if value[:nested] %}
                {{value[:type]}}.parse_string_parameter(scanner, depth + 1, value, context.collection({{_key}}))
              {% else %}
                context.append_field({{_key}}, coerce_{{key.id}}(value).as({{value[:base_type].id}}))
              {% end %}
            {% elsif value[:nested] %}
              {{value[:type]}}.parse_string_parameter(scanner, depth + 1, value, context.object({{_key}}))
            {% else %}
              context.set_field({{_key}}, coerce_{{key.id}}(value).as({{value[:type].id}}))
            {% end %}
          {% end %}
          end
        end

        # :nodoc:
        def self.parse_json_parameter(key : String, pull : JSON::PullParser, context)
          case
          {% for key, value in mapping %}
            {% _key = key.id.stringify %}
            when match_json_key?(key, {{_key}})
            {% if value[:nested] %}
              {% if value[:array] %}
                {{value[:type]}}.parse_json_array(pull, context.collection({{_key}}))
              {% else %}
                {{value[:type]}}.parse_json_object(pull, context.object({{_key}}))
              {% end %}
            {% else %}
              context.set_field({{_key}}, coerce_{{key.id}}(pull).as({{value[:type].id}}))
            {% end %}
          {% end %}
          end
        end

        {% for name, options in mapping %}
          {% if options[:nested] %}
            private def __{{name.id}}_populator(context, index = -1) : {{options[:type]}}
              {% if options[:populator] %}
                {% if options[:array] %}
                  {{options[:populator].id}}(collection: {{name.id}}, context: context, index: index)
                {% else %}
                  {{options[:populator].id}}(model: {{name.id}}, context: context)
                {% end %}
              {% else %}
                {% if options[:array] %}
                  raise ArgumentError if index < 0
                  if self{{name.id}}.size < index
                    form = {{options[:type]}}.new({{options[:base_type]}}.new)
                    {{name.id}} << form
                    form
                  else
                    {{name.id}}[index]
                  end
                {% else %}
                  self.{{name.id}} ||= {{options[:base_type]}}.new
                {% end %}
              {% end %}
            end
          {% else %}
            # :nodoc:
            def self.coerce_{{name.id}}(value : String)
              coercer.coerce(value, {{options[:stringified_type]}})
            rescue ArgumentError
              raise ::FormObject::TypeCastError.new(value, {{name.id.stringify}}, value.class.name, {{options[:stringified_type]}})
            end

            # :nodoc:
            def self.coerce_{{name.id}}(value : HTTP::FormData::Part)
              coerce_{{name.id}}(value.body.gets_to_end)
            end

            # :nodoc:
            def self.coerce_{{name.id}}(pull : JSON::PullParser)
              {{options[:type]}}.new(pull)
            rescue ex : JSON::ParseException
              raise ::FormObject::TypeCastError.new(pull.read_raw, {{name.id.stringify}}, pull.read_raw.class.name, {{options[:type].stringify}})
            end
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
