module FormObject
  module Mapping
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

    macro path(value, json_path = nil)
      private def match_key?(key, expected_key, array = false)
        "{{value.id}}[#{expected_key}]#{array ? "[]" : ""}" == key
      end
    end

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
        @{{name.id}}{{".not_nil!".id unless options[:null]}}
      end

      def {{name.id}}?
        @{{name.id}}
      end

      {% if options[:array] %}
        def append_{{name.id}}(value : String)
          (@{{name.id}} ||= [] of {{options[:base_type]}}) << coercer.coerce(value, {{options[:base_type].stringify}}).as({{options[:base_type]}})
        end

        def append_{{name.id}}(value : HTTP::FormData::Part)
          append_{{name.id}}(value.body.gets_to_end)
        end
      {% end %}

      setter :{{name.id}}

      def {{name.id}}=(value : String)
        @{{name.id}} = coercer.coerce(value, {{options[:stringified_type]}}).as({{options[:type].id}})
      rescue ArgumentError
        raise ::FormObject::TypeCastError.new(value, {{name.id.stringify}}, value.class.name, {{options[:stringified_type]}})
      end

      def {{name.id}}=(value : HTTP::FormData::Part)
        self.{{name.id}} = value.body.gets_to_end
      end

      def {{name.id}}=(pull : JSON::PullParser)
        @{{name.id}} = {{options[:type]}}.new(pull)
      rescue ex : JSON::ParseException
        raise ::FormObject::TypeCastError.new(pull.read_raw, {{name.id.stringify}}, pull.read_raw.class.name, {{options[:type].stringify}})
      end
    end

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
              resource.{{value[:origin].id}} = {{field.id}}?
            {% end %}
          {% end %}
        end

        private def parse_form_data_part(key : String, value : HTTP::FormData::Part)
          case
          {% for key, value in mapping %}
            {% _key = key.id.stringify %}
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
          {% for key, value in mapping %}
            {% _key = key.id.stringify %}
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
          {% for key, value in mapping %}
            when match_json_key?(key, {{key.id.stringify}})
              self.{{key.id}} = pull
          {% end %}
          end
        end
      {% end %}
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
