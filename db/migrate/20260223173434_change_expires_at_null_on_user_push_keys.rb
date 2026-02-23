class ChangeExpiresAtNullOnUserPushKeys < ActiveRecord::Migration[8.1]
  def change
    change_column_null :user_push_keys, :expires_at, false
  end
end
