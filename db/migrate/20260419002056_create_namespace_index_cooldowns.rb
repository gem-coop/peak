class CreateNamespaceIndexCooldowns < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_index_cooldowns do |t|
      t.timestamps
    end
  end
end
