class CreateNamespaceGemVersionReferences < ActiveRecord::Migration[8.2]
  def change
    create_table :namespace_gem_version_references do |t|
      t.string :name, null: false, index: true
      t.string :operator, null: false
      t.string :ref, null: false

      t.timestamps
      t.index [:name, :operator, :ref], unique: true, name: "namespace_gem_version_references_uniqueness"
    end
  end
end
