class AddMirrorLastProcessed < ActiveRecord::Migration[8.1]
  def change
    add_column :namespace_index_mirrors, :last_started_at, :datetime, null: false, default: Time.at(0)
    add_column :namespace_index_mirrors, :last_processed_at, :datetime, null: false, default: Time.at(0)
  end
end
