class Contact < Jennifer::Model::Base
  with_timestamps

  mapping(
    id:          Primary32,
    name:        String,
    ballance:    PG::Numeric?,
    age:         {type: Int32, default: 10},
    gender:      {type: String?, default: "male"},
    description: String?,
    created_at:  Time?,
    updated_at:  Time?,
    user_id:     Int32?,
    tags:        Array(Int32)?
  )

  has_one :addresses, Address, inverse_of: :contact

  validates_inclusion :age, 13..75
  validates_length :name, minimum: 1
  validates_with_method :name_check

  def name_check
    if @description && @description.not_nil!.size > 10
      errors.add(:description, "Too large description")
    end
  end
end

class Address < Jennifer::Model::Base
  with_timestamps

  mapping(
    # id: Primary32,
    # main: Bool,
    # street: String,
    # contact_id: Int32?,
    # details: JSON::Any?,
    # created_at: Time?,
    # updated_at: Time?
    id: Primary32,
    main: { type: Bool, default: true },
    street: String?,
    contact_id: Int32?,
    details: JSON::Any?,
    created_at: Time?,
    updated_at: Time?
  )

  validates_format :street, /st\.|street/

  belongs_to :contact, Contact
end