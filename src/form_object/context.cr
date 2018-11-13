module FormObject
  class Context
    alias Any = String | Int16 | Int64 | Int32 | Int8 | Float32 | Float64 | Bool | Time | JSON::Any |
      Array(String) | Array(Int16) | Array(Int64) | Array(Int32) | Array(Int8) | Array(Float32) | Array(Float64) | Array(Bool) | Array(Time) | Array(JSON::Any)

    getter properties : Hash(String, Any), objects : Hash(String, Context), collections : Hash(String, Array(Context))

    def initialize
      @properties = {} of String => Any
      @objects = {} of String => Context
      @collections = {} of String => Array(Context)
    end

    def clear
      @properties = {} of String => Any
      @objects = {} of String => Context
      @collections = {} of String => Array(Context)
    end

    def each_field
      @properties.each do |field, value|
        yield field, value
      end
    end

    def append_field(field, value : T) forall T
      @properties[field] ||= ([] of T).as(Any)
      @properties[field].as(Array(T)) << value
    end

    def set_field(field, value)
      @properties[field] = value.as(Any)
    end
  end
end
