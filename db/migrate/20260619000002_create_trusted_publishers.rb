class CreateTrustedPublishers < ActiveRecord::Migration[8.1]
  def change
    create_table :trusted_publishers do |t|
      t.string :type, null: false
      t.references :namespace, null: false, foreign_key: true
      t.references :gem, null: true, foreign_key: { to_table: :namespace_gems }
      t.string :gem_name, null: false
      t.references :provider, null: false, foreign_key: { to_table: :oidc_providers }

      # GitHub Actions claim policy
      t.string :repository_owner
      t.string :repository_name
      t.string :workflow_filename
      t.string :environment
      t.string :ref

      t.timestamps
    end
  end
end
