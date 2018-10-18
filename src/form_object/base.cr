require "./mapping"
require "./coercer"

module FormObject
  abstract class AbstractForm
    include Mapping

    abstract def resource
    abstract def validate!
    abstract def sync

    private abstract def match_key?(key, expected_key, array)
    private abstract def parse_form_data_part(key : String, value : HTTP::FormData::Part)
    private abstract def parse_string_parameter(key : String, value : String)
    private abstract def parse_json_parameter(key : String, pull : JSON::PullParser)

    def verify(request : HTTP::Request)
      parse(request)
      valid?
    end

    def save
      sync
      resource.save
    end

    def save
      yield self
    end

    private def parse(request)
      request.query_params.each do |key, value|
        parse_string_parameter(key, value)
      end

      case request.headers["Content-Type"]?
      when /^application\/x-www-form-urlencoded/
        return if request.body.nil? || request.content_length.nil?
        HTTP::Params.parse(request.body.not_nil!.gets_to_end).each do |key, value|
          parse_string_parameter(key, value)
        end
      when /^multipart\/form-data/
        return if request.body.nil? || request.content_length.nil?
        HTTP::FormData.parse(request) do |part|
          parse_form_data_part(part.name, part)
        end
      when /^application\/json/
        begin
          body = request.body.to_s
          pull = JSON::PullParser.new(body)

          location = pull.location
          pull.read_begin_object
          while pull.kind != :end_object
            key = pull.read_object_key
            parse_json_parameter(key, pull)
          end

          pull.read_next

        rescue JSON::ParseException
        end
      end
    end

    private def __before_validation_callback
      true
    end

    private def __after_validation_callback
      true
    end
  end

  abstract class Base(T) < AbstractForm
    include Jennifer::Model::Validation

    def errors
      @errors ||= Jennifer::Model::Errors.new(resource)
    end

    getter resource : T
    private getter coercer : Coercer

    def initialize(@resource, coercer = Coercer.new)
      @coercer = coercer
    end

    macro inherited
      ::Jennifer::Model::Validation.inherited_hook

      # :nodoc:
      def self.superclass
        {{@type.superclass}}
      end

      macro finished
        ::Jennifer::Model::Validation.finished_hook
      end
    end
  end
end
