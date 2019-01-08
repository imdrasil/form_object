# :nodoc:
class HTTP::Request
  DEFAULT_MAX_BODY_SIZE = UInt64.new(8 * 1024 ** 2)

  @cached_body : IO::Memory?

  def body
    cached_body
  end

  def self.max_body_size
    DEFAULT_MAX_BODY_SIZE
  end

  private def cached_body
    @cached_body ||= begin
      unless @body.nil?
        io = IO::Memory.new
        IO.copy(@body.not_nil!, io, self.class.max_body_size)
        io.rewind
        io
      end
    end
  end
end
