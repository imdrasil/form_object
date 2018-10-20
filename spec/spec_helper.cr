require "spec"
require "./support/jennifer"
require "./support/models"
require "./support/factories"

require "../src/form_object"

I18n.init

Spec.before_each do
  Jennifer::Adapter.adapter.begin_transaction
end

Spec.after_each do
  Jennifer::Adapter.adapter.rollback_transaction
end

alias CF = FormObject::Base(Contact)

def build_form(&block)
  io = IO::Memory.new

  builder = HTTP::FormData::Builder.new(io, "boundary")
  yield(builder)
  builder.finish
  {io, builder}
end

def form_data(&block)
  io, builder = build_form { |b| yield b }
  headers = HTTP::Headers{"Content-Type" => builder.content_type}

  request = HTTP::Request.new("POST", "/", body: io.to_s, headers: headers).tap do |r|
    r.content_length = io.to_s.size
  end
end

def form_data(data : Array)
  form_data do |builder|
    data.each do |options|
      builder.field(options[0].to_s, options[1])
    end
  end
end

def _url_query(data : Array)
  return "" if data.empty?
  query_pairs = data.map { |pair| "#{pair[0]}=#{pair[1]}" }
  "#{query_pairs.join("&")}"
end

def url_encoded_form_data(data : Array)
  body = _url_query(data)
  headers = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}

  request = HTTP::Request.new("POST", "/", body: body, headers: headers).tap do |r|
    r.content_length = body.size
  end
end

def json_data(body, query_args = [] of Array(String))
  HTTP::Request.new(
    "POST",
    headers: HTTP::Headers{"Content-Type" => "application/json"},
    resource: "/" + (query_args.empty? ? "" : "?#{_url_query(query_args)}"),
    body: body.to_json
  )
end
