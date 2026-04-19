class CreateNamespaceMirrors < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_index_mirrors do |t|
      t.belongs_to :index, null: false, foreign_key: { to_table: :namespace_indexes }
      t.string :upstream_url, null: false

      t.timestamps
    end
  end
end
