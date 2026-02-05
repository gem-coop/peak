class AddPushKeyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :push_key, :string

    up_only { User.find_each(&:regenerate_push_key) }
    change_column_null :users, :push_key, false
    add_index :users, :push_key, unique: true
  end
end
