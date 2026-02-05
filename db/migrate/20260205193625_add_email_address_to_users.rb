class AddEmailAddressToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_address, :string, null: false, index: { unique: true }
  end
end
