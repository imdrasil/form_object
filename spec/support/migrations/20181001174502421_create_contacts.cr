class CreateContacts < Jennifer::Migration::Base
  def up
    create_enum(:gender_enum, ["male", "female"])
    create_table(:contacts) do |t|
      t.string :name, {:size => 30}
      t.integer :age
      t.integer :tags, {:array => true}
      t.decimal :balance
      t.field :gender, :gender_enum
      t.timestamps true
    end
  end

  def down
    drop_table :contacts
    drop_enum :gender_enum
  end
end
