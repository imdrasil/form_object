require "spec"
require "http"
require "./support/jennifer"
require "./support/models"
require "./support/factories"

require "../src/form_object"

I18n.init

def form_data(&block)
  io = IO::Memory.new

  builder = HTTP::FormData::Builder.new(io, "boundary")
  yield(builder)
  builder.finish
  request = HTTP::Request.new("POST", "/", body: io.to_s, headers: HTTP::Headers{"Content-Type" => builder.content_type}).tap do |r|
    r.content_length = io.to_s.size
  end
end

def json_data(body, query_args = {} of String => String)
  query_pairs = query_args.map { |key, value| "#{key}=#{value}" }
  HTTP::Request.new(
    "GET",
    headers: HTTP::Headers{"Content-Type" => "application/json"},
    resource: "/" + (query_pairs.empty? ? "" : "?#{query_pairs.join("&")}"),
    body: body.to_json
  )
end
