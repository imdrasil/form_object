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

      private def match_json_path?(depth : Int)
        depth + 1 == JSON_PATH.size
      end

      private def current_json_key(depth)
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
      private def match_key?(key, expected_key, array = false)
        "{{value.id}}[#{expected_key}]#{array ? "[]" : ""}" == key
      end

      private def match_root(scanner)
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
    # * `#attribute` - getter with `not_nil!` check for non-nil field
    # * `#attribute?` - getter without `not_nil!` check
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
          defined: false
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
        def initialize(@resource, @coercer = FormObject::Coercer.new)
          {% for key, value in mapping %}
            {% unless value[:virtual] %}
              @{{key.id}} = @resource.{{value[:origin].id}}
            {% end %}
          {% end %}
        end

        # :nodoc:
        def sync
          {% for field, value in mapping %}
            {% unless value[:virtual] %}
              resource.{{value[:origin].id}} = {{field.id}}
            {% end %}
          {% end %}
        end

        private def parse_form_data_part(key : String, value : HTTP::FormData::Part)
          parse_string_parameter(key, value)
        end

        private def parse_string_parameter(key : String, value)
          scanner = StringScanner.new(key)
          depth = match_root(scanner)
          return if depth.nil?
          field = read_field(scanner, depth)
          case field
          {% for key, value in mapping %}
            {% _key = key.id.stringify %}
            when {{_key}}
            {% if value[:array] %}
              return unless read_array_suffix(scanner)
              @current_context.append_field({{_key}}, self.class.coerce_{{key.id}}(value).as({{value[:base_type].id}}))
            {% else %}
              @current_context.set_field({{_key}}, self.class.coerce_{{key.id}}(value).as({{value[:type].id}}))
            {% end %}
          {% end %}
          end
        end

        private def parse_json_parameter(key : String, pull : JSON::PullParser)
          case
          {% for key, value in mapping %}
          {% _key = key.id.stringify %}
            when match_json_key?(key, {{_key}})
            @current_context.set_field({{_key}}, self.class.coerce_{{key.id}}(pull).as({{value[:type].id}}))
          {% end %}
          end
        end

        private def assign_fields
          @current_context.each_field do |field, value|
            case field
            {% for key, value in mapping %}
              {% _key = key.id.stringify %}
              when {{_key}}
              {% if value[:array] %}
                self.{{key.id}} = Ifrit.typed_array_cast(value.as(Array), {{value[:base_type].id}})
              {% else %}
                self.{{key.id}} = value.as({{value[:type].id}})
              {% end %}
            {% end %}
            end
          end
        end

        {% for name, options in mapping %}
          def self.coerce_{{name.id}}(value : String)
            coercer.coerce(value, {{options[:stringified_type]}})
          rescue ArgumentError
            raise ::FormObject::TypeCastError.new(value, {{name.id.stringify}}, value.class.name, {{options[:stringified_type]}})
          end

          def self.coerce_{{name.id}}(value : HTTP::FormData::Part)
            coerce_{{name.id}}(value.body.gets_to_end)
          end

          def self.coerce_{{name.id}}(pull : JSON::PullParser)
            {{options[:type]}}.new(pull)
          rescue ex : JSON::ParseException
            raise ::FormObject::TypeCastError.new(pull.read_raw, {{name.id.stringify}}, pull.read_raw.class.name, {{options[:type].stringify}})
          end
        {% end %}
      {% end %}
    end

    # TODO: Future feature
    macro object(name, klass)
      {% klass_name = "#{name.id.camelcase}Form".id %}

      class {{klass_name}} < FormObject::Base({{klass}})
        {{yield}}
      end
    end
  end
end
