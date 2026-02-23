class CreateNamespaceGemVersionLinkings < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_gem_version_linkings do |t|
      t.references :version, null: false
      t.references :link, null: false
      t.index [:version_id, :link_id], unique: true, name: "index_namespace_gem_version_linking_uniqueness"

      t.timestamps
    end
  end
end
