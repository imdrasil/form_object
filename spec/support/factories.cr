require "factory"

class ContactFactory < Factory::Jennifer::Base
  argument_type (Array(Int32) | Int32 | PG::Numeric | String?)

  attr :name, "Deepthi"
  attr :age, 28
  attr :description, nil
  attr :gender, "female"
end

class AddressFactory < Factory::Jennifer::Base
  attr :main, false
  sequence(:street) { |i| "Ant st. #{i}" }
  attr :contact_id, nil, Int32?
  attr :details, nil, JSON::Any?
end