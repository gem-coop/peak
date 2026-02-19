class AddEmailAddressVerifiedAtToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_address_verified_at, :datetime
  end
end
