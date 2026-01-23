class CreateNamespaces < ActiveRecord::Migration[8.1]
  def change
    create_table :namespaces do |t|
      t.string :name, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
