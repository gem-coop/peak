class AddLineToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :namespace_gem_versions, :line, :string

    up_only { Namespace::Gem::Version.includes(:references).find_each { _1.update line: _1.compute_line } }
    safety_assured { change_column_null :namespace_gem_versions, :line, false }
  end
end
