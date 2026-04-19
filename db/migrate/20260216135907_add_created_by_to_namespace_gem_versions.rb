class AddCreatedByToNamespaceGemVersions < ActiveRecord::Migration[8.1]
  class User < ActiveRecord::Base; end

  def change
    add_reference :namespace_gem_versions, :created_by

    up_only do
      User.reset_column_information
      # create Peak system user with our no-callback User class
      User.create_with(name: "gem.coop system").find_or_create_by!(email_address: "support@gem.coop")
      # update the existing versions
      Namespace::Gem::Version.update_all created_by_id: Peak.system_user.id
    end

    change_column_null :namespace_gem_versions, :created_by_id, false
  end
end
