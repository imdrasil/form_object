require "./mapping"
require "./coercer"

module FormObject
  # Base abstract form object class.
  #
  # Works with any kind of object but needs some abstract methods implementation:
  #
  # - #persist
  # - #valid?
  abstract class AbstractForm
    include Mapping

    # Returns whether form object is valid.
    abstract def valid?

    # Synchronizes attributes and persists resource.
    abstract def save

    # Persists resource.
    abstract def persist

    private abstract def match_key?(key, expected_key, array)
    private abstract def match_json_path?(depth : Int)
    private abstract def current_json_key(depth)
    private abstract def parse_form_data_part(key : String, value : HTTP::FormData::Part)
    private abstract def parse_string_parameter(key : String, value : String)
    private abstract def parse_json_parameter(key : String, pull : JSON::PullParser)

    private getter coercer : Coercer

    def initialize(@coercer = Coercer.new)
    end

    # Parses given request data, assigns them and validates.
    def verify(request : HTTP::Request)
      parse(request)
      valid?
    end

    def save
      sync
      persist
    end

    private def match_key?(key, expected_key, array : Bool = false)
      "#{expected_key}#{array ? "[]" : ""}" == key
    end

    private def match_json_path?(depth)
      depth == -1
    end

    private def match_json_key?(key, expected_key)
      expected_key == key
    end

    private def current_json_key(depth)
      ""
    end

    private def parse(request)
      read_query_params(request)

      case request.headers["Content-Type"]?
      when /^application\/x-www-form-urlencoded/
        read_url_encoded_form(request)
      when /^multipart\/form-data/
        read_multipart_form(request)
      when /^application\/json/
        read_json_form(request)
      end
    end

    private def read_query_params(request)
      request.query_params.each do |key, value|
        parse_string_parameter(key, value)
      end
    end

    private def read_url_encoded_form(request)
      return if request.body.nil? || request.content_length.nil?
      HTTP::Params.parse(request.body.not_nil!.gets_to_end).each do |key, value|
        parse_string_parameter(key, value)
      end
    end

    private def read_multipart_form(request)
      return if request.body.nil? || request.content_length.nil?
      HTTP::FormData.parse(request) do |part|
        parse_form_data_part(part.name, part)
      end
    end

    private def read_json_form(request)
      body = request.body.to_s
      pull = JSON::PullParser.new(body)

      go_deep_json(pull)
    rescue JSON::ParseException
    end

    private def go_deep_json(pull, depth = -1)
      if match_json_path?(depth)
        pull.read_begin_object
        while pull.kind != :end_object
          key = pull.read_object_key

          parse_json_parameter(key, pull)
        end
      else
        key = current_json_key(depth)
        pull.on_key(key) { go_deep_json(pull, depth + 1) }
      end
    end

    private def __before_validation_callback
      true
    end

    private def __after_validation_callback
      true
    end
  end
end
