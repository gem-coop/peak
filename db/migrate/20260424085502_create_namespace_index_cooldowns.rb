class CreateNamespaceIndexCooldowns < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_index_cooldowns do |t|
      t.references :index, null: false, index: false
      t.interval :interval, null: false, default: 48.hours.to_i
      t.index [:index_id, :interval], unique: true
      t.timestamps
    end
  end
end
