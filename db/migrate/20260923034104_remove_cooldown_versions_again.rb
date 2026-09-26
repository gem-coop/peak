class RemoveCooldownVersionsAgain < ActiveRecord::Migration[8.1]
  def change
    drop_table :cooldown_versions, if_exists: true
  end
end
