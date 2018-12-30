require "http/request"
require "http/formdata"
require "http/multipart"

require "./form_object/http"

require "./form_object/exceptions"
require "./form_object/base"
require "./form_object/module"

module FormObject
  VERSION = "0.2.0"

  def self.local_time_zone
    Time::Location.local
  end
end
