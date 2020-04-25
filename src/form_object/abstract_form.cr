require "./mapping"
require "./coercer"
require "./context"

module FormObject
  # Base abstract form object class.
  #
  # Works with any kind of object but needs some abstract methods implementation:
  #
  # - #persist
  # - #valid?
  abstract class AbstractForm
    include Mapping

    module ClassMethods
      private abstract def match_root(scanner)
      abstract def parse_string_parameter(key, value, context)
      private abstract def parse_form_data_part(key, value, context)
      private abstract def parse_json_parameter(key, value, context)
      private abstract def match_json_key?(key, expected_key)
    end

    extend ClassMethods

    # Returns whether form object is valid.
    abstract def valid?

    # Synchronizes attributes and persists resource.
    abstract def save

    # Persists resource.
    abstract def persist

    abstract def assign_fields(context)

    def self.coercer
      @@coercer ||= Coercer.new
    end

    def initialize
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

    def skip
      raise SkipException.new
    end

    private def self.match_root(_scanner)
      0
    end

    private def self.read_field(scanner, depth : Int32 = 1)
      if depth == 0
        scanner.scan(/[\w\d_-]+/)
      else
        return if scanner.scan(/\[/).nil?
        field = scanner.scan(/[\w\d_-]+/)
        return if field.nil? || scanner.scan(/\]/).nil?
        field
      end
    end

    private def self.read_array_suffix(scanner)
      !scanner.scan(/\[\]/).nil?
    end

    private def self.match_json_path?(depth)
      depth == -1
    end

    private def self.match_json_key?(key, expected_key)
      expected_key == key
    end

    private def self.current_json_key(depth)
      ""
    end

    def self.parse(request)
      body = request.body
      body.seek(0) if body

      context = Context.new
      read_query_params(request, context)

      case request.headers["Content-Type"]?
      when /^application\/x-www-form-urlencoded/
        read_url_encoded_form(request, context)
      when /^multipart\/form-data/
        read_multipart_form(request, context)
      when /^application\/json/
        read_json_form(request, context)
      else
      end
      context
    end

    private def parse(request)
      context = self.class.parse(request)

      assign_fields(context)
    end

    def self.read_query_params(request, context)
      HTTP::Params.parse(URI.parse(request.resource).query || "") do |key, value|
        parse_string_parameter(key, value, context)
      end
    end

    def self.read_url_encoded_form(request, context)
      return if request.body.nil? || request.content_length.nil?
      HTTP::Params.parse(request.body.not_nil!.gets_to_end) do |key, value|
        parse_string_parameter(key, value, context)
      end
    end

    def self.read_multipart_form(request, context)
      return if request.body.nil? || request.content_length.nil?
      HTTP::FormData.parse(request) do |part|
        parse_form_data_part(part.name, part, context)
      end
    end

    def self.read_json_form(request, context)
      body = request.body.to_s
      pull = JSON::PullParser.new(body)

      go_deep_json(pull, context)
    rescue JSON::ParseException
    end

    private def self.parse_form_data_part(key : String, value : HTTP::FormData::Part, context)
      parse_string_parameter(key, value, context)
    end

    def self.go_deep_json(pull, context, depth = -1)
      if match_json_path?(depth)
        parse_json_object(pull, context)
      else
        key = current_json_key(depth)
        pull.on_key(key) { go_deep_json(pull, context, depth + 1) }
      end
    end

    def self.parse_json_object(pull, context)
      pull.read_object do |field|
        parse_json_parameter(field, pull, context)
      end
    end

    def self.parse_json_array(pull, context_collection)
      pull.read_array do
        context = context_collection.next_object
        parse_json_object(pull, context)
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
