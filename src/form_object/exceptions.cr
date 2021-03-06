module FormObject
  class BaseError < Exception
  end

  class TypeCastError < BaseError
    getter name : String, source : String, target : String

    def initialize(value, @name, @source, @target)
      super("Can't cast parameter #{name} = \"#{value}\" from #{source} to #{target}", nil)
    end
  end

  class NotAssignedError < BaseError
    def initialize(value)
      super("Value of #{value} is nil but expected to be set.")
    end
  end

  class SkipException < Exception
  end
end
