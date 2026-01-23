class CreateNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_gem_versions do |t|
      t.references :gem, null: false, index: true
      t.string :ref, null: false

      t.timestamps
      t.index [:gem_id, :ref], unique: true, name: "index_namepace_gem_versions_uniqueness"
    end
  end
end
