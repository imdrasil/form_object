require "./i_context"
require "./context_collection"

module FormObject
  class Context < IContext
    getter properties : Hash(String, Any),
      objects : Hash(String, Context),
      collections : Hash(String, ContextCollection)

    def initialize
      @properties = {} of String => Any
      @objects = {} of String => Context
      @collections = {} of String => ContextCollection
    end

    def clear
      @properties = {} of String => Any
      @objects = {} of String => Context
      @collections = {} of String => ContextCollection
    end

    def each_field
      @properties.each do |field, value|
        yield field, value
      end
    end

    def each_object
      @objects.each do |field, context|
        yield field, context
      end
    end

    def each_collection
      @collections.each do |field, collection|
        yield field, collection
      end
    end

    def append_field(field, value : T) forall T
      properties[field] ||= ([] of T).as(Any)
      properties[field].as(Array(T)) << value
    end

    def set_field(field, value)
      properties[field] = value.as(Any)
    end

    def object(name : String)
      objects[name] ||= Context.new
    end

    def collection(name : String)
      @collections[name] ||= ContextCollection.new
    end
  end
end
