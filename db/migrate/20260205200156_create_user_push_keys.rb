class CreateUserPushKeys < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :push_key, :string

    create_table :user_push_keys do |t|
      t.references :user, null: false, index: true
      t.string :token, null: false
      t.datetime :expires_at

      t.timestamps
    end
  end
end
