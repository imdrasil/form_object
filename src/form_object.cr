require "http/request"
require "http/formdata"
require "http/multipart"

require "./form_object/base"
require "./form_object/exceptions"

module FormObject
  VERSION = "0.1.0"

  def self.local_time_zone
    Time::Location.local
  end
end
