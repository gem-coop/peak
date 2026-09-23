class RemoveCooldownVersionsAgain < ActiveRecord::Migration[8.1]
  def change
    drop_table :cooldown_versions if table_exists? :cooldown_versions
  end
end
