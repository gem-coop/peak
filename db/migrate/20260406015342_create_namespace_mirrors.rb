class CreateNamespaceMirrors < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_mirrors do |t|
      t.belongs_to :namespace, null: false, foreign_key: true
      t.string :upstream

      t.timestamps
    end
  end
end
