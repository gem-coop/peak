class DropNamespaceGemInfos < ActiveRecord::Migration[8.1]
  def change
    drop_table :namespace_gem_infos
  end
end
