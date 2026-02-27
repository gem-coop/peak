class AddSummaryToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :namespace_gem_versions, :summary, :string

    up_only { Namespace::Gem::Version.update_all summary: "" }
    change_column_null :namespace_gem_versions, :summary, false
  end
end
