class CreateNamespaceAccesses < ActiveRecord::Migration[8.2]
  def change
    create_table :namespace_accesses do |t|
      t.references :namespace, null: false, index: true
      t.references :user, null: false, index: true
      t.string :role, null: false, default: "plain"

      t.timestamps
    end
  end
end
