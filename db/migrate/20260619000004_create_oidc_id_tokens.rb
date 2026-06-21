class CreateOidcIdTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :oidc_id_tokens do |t|
      t.references :provider, null: false, foreign_key: { to_table: :oidc_providers }
      t.references :trusted_publisher, null: false, foreign_key: true
      t.references :push_key, null: true, foreign_key: { to_table: :trusted_publisher_push_keys }
      t.string :jti, null: false
      t.json :claims, null: false, default: {}

      t.timestamps
      t.index [:provider_id, :jti], unique: true
    end
  end
end
