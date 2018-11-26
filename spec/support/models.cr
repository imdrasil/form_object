class Contact < Jennifer::Model::Base
  with_timestamps

  mapping(
    id:          Primary32,
    name:        String?,
    balance:     PG::Numeric?,
    age:         {type: Int32, default: 10},
    gender:      {type: String?, default: "male"},
    tags:        Array(Int32)?,
    created_at:  Time?,
    updated_at:  Time?
  )

  has_one :address, Address, inverse_of: :contact
  has_many :addresses, Address, inverse_of: :contact

  validates_inclusion :age, 13..75
  validates_length :name, minimum: 1
end

class Address < Jennifer::Model::Base
  with_timestamps

  mapping(
    id: Primary32,
    main: { type: Bool, default: true },
    street: String?,
    contact_id: Int32?,
    created_at: Time?,
    updated_at: Time?
  )

  validates_format :street, /st\.|street/

  belongs_to :contact, Contact
end