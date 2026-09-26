class RemoveCooldownVersionsAgain < ActiveRecord::Migration[8.1]
  def change
    drop_table :cooldown_versions, if_exists: true do
      # allow it to be reversed, since we don't care anymore
    end
  end
end
