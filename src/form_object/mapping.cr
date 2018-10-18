module FormObject
  module Mapping
    macro mapping(**properties)
      mapping({{properties}})
    end

    macro mapping(properties, path = nil, nested = false)
      private def match_key?(key, expected_key, array = false)
        {% if path != nil %}
          "{{path.id}}[#{expected_key}]#{array ? "[]" : ""}" == key
        {% else %}
          "#{expected_key}#{array ? "[]" : ""}" == key
        {% end %}
      end

      {% for key, value in properties %}
        {%
          properties[key] = {type: value} unless value.is_a?(HashLiteral) || value.is_a?(NamedTupleLiteral)
          options = properties[key]
          options[:stringified_type] = options[:type].stringify
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
            options[:null] = false
          end
          options[:origin] = key unless options[:origin]
        %}
      {% end %}

      {% for key, value in properties %}
        {% if value[:null] %}
          @{{key.id}} : {{value[:type]}}
        {% else %}
          validates_presence :{{key}}

          @{{key.id}} : {{value[:type]}}?
        {% end %}

        def {{key.id}}
          @{{key.id}}{{".not_nil!".id unless value[:null]}}
        end

        def {{key.id}}?
          @{{key.id}}
        end

        {% if value[:array] %}
          def append_{{key.id}}(value : String)
            (@{{key.id}} ||= [] of {{value[:base_type]}}) << coercer.coerce(value, {{value[:base_type].stringify}}).as({{value[:base_type]}})
          end

          def append_{{key.id}}(value : HTTP::FormData::Part)
            append_{{key.id}}(value.body.gets_to_end)
          end
        {% end %}

        def {{key.id}}=(value : String)
          @{{key.id}} = coercer.coerce(value, {{value[:stringified_type]}}).as({{value[:type].id}})
        rescue TypeCastError
          raise ::FormObject::TypeCastError.new(value, {{key.stringify}}, value.class.name, {{value[:stringified_type]}})
        end

        def {{key.id}}=(value : HTTP::FormData::Part)
          self.{{key.id}} = value.body.gets_to_end
        end

        def {{key.id}}=(pull : JSON::PullParser)
          @{{key.id}} = {{value[:type]}}.new(pull)
        rescue ex : JSON::ParseException
          raise ::FormObject::TypeCastError.new(pull.read_raw, {{key.stringify}}, pull.read_raw.class.name, {{value[:type].stringify}})
        end
      {% end %}

      def initialize(resource, coercer = FormObject::Coercer.new)
        super
        {% for key, value in properties %}
          {% unless value[:virtual] %}
            @{{key.id}} = resource.{{value[:origin].id}}
          {% end %}
        {% end %}
      end

      # :nodoc:
      def sync
        {% for field, value in properties %}
          resource.{{value[:origin].id}} = {{field.id}}
        {% end %}
      end

      private def parse_form_data_part(key : String, value : HTTP::FormData::Part)
        case
        {% for key, value in properties %}
          {% _key = key.stringify %}
          {% if value[:array] %}
            when match_key?(key, {{_key}}, true)
              append_{{key.id}}(value)
          {% else %}
            when match_key?(key, {{_key}})
              self.{{key.id}} = value
          {% end %}
        {% end %}
        end
      end

      private def parse_string_parameter(key : String, value : String)
        case
        {% for key, value in properties %}
          {% _key = key.stringify %}
          {% if value[:array] %}
            when match_key?(key, {{_key}}, true)
              append_{{key.id}}(value)
          {% else %}
            when match_key?(key, {{_key}})
              self.{{key.id}} = value
          {% end %}
        {% end %}
        end
      end

      private def parse_json_parameter(key : String, pull : JSON::PullParser)
        case
        {% for key, value in properties %}
          when match_key?(key, {{key.stringify}})
            self.{{key.id}} = pull
        {% end %}
        end
      end
    end

    # TODO: finish
    macro object(name, klass)
      {% klass_name = "#{name.id.camelcase}Form".id %}

      class {{klass_name}} < FormObject::Base({{klass}})
        {{yield}}
      end
    end
  end
end
