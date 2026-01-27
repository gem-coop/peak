class AddExecutablesAndLicensesToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    change_table :namespace_gem_versions do |t|
      t.json :executables, null: false, default: []
      t.json :licenses,    null: false, default: []
    end
  end
end
