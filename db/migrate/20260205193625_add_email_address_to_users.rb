class AddEmailAddressToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_address, :string, null: false
    add_index :users, :email_address, unique: true
  end
end
