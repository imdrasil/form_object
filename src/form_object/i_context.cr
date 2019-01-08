module FormObject
  abstract class IContext
    alias Any = String | Int16 | Int64 | Int32 | Int8 | Float32 | Float64 | Bool | Time | JSON::Any |
      Array(String) | Array(Int16) | Array(Int64) | Array(Int32) | Array(Int8) | Array(Float32) |
      Array(Float64) | Array(Bool) | Array(Time) | Array(JSON::Any)

    abstract def append_field(field, value)

    abstract def set_field(field, value)

    abstract def object(name : String)

    abstract def collection(name : String)
  end
end
