class CreateAddresses < Jennifer::Migration::Base
  def up
    create_table(:addresses) do |t|
      t.integer :contact_id, {:null => true}
      t.string :street
      t.bool :main, {:default => false}

      t.foreign_key :contacts

      t.timestamps
    end
  end

  def down
    drop_foreign_key :addresses, :contacts
    drop_table :addresses
  end
end
