class AddPlatformToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  def change
    add_reference :namespace_gem_versions, :platform, index: true

    up_only { Namespace::Gem::Version.update_all platform_id: Peak::Platform.default.id }
    change_column_null :namespace_gem_versions, :platform_id, false
  end
end
