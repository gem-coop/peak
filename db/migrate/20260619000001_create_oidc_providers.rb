class CreateOidcProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :oidc_providers do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :issuer, null: false

      t.timestamps
      t.index :issuer, unique: true
    end
  end
end
