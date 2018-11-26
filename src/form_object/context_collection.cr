require "set"

module FormObject
  class Context < IContext; end

  class ContextCollection < IContext
    getter bucket

    delegate :size, :empty?, :[], to: :bucket

    def initialize
      @bucket = [] of Context
      @fields = Set(String).new
    end

    def current_object
      return next_object if @bucket.empty?
      @bucket.last
    end

    def next_object
      @bucket << Context.new
      @bucket.last
    end

    def object_for(field : String)
      if @fields.includes?(field)
        @fields.clear
        @bucket << Context.new
      end
      @fields << field
      current_object
    end

    def append_field(field, value : T) forall T
      properties = object_for(field).properties[field]
      properties[field] ||= ([] of T).as(Any)
      properties[field].as(Array(T)) << value
    end

    def set_field(field, value)
      object_for(field).properties[field] = value.as(Any)
    end

    def object(name : String)
      object_for(field).objects[name] ||= Context.new
    end

    def collection(name : String)
      object_for(field).collections[name] ||= ContextCollection.new
    end

    def each_context
      @bucket.each do |context|
        yield context
      end
    end
  end
end
