class CreateNamespaceGemInfos < ActiveRecord::Migration[8.1]
  def change
    create_table :namespace_gem_infos do |t|
      t.references :gem, null: false
      t.text :contents, null: false, default: ""
      t.string :checksum, null: false, default: ""
      t.string :envelope, null: false, default: ""

      t.timestamps
    end
  end
end
