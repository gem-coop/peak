class CreateTrustedPublisherPushKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :trusted_publisher_push_keys do |t|
      t.references :trusted_publisher, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false

      t.timestamps
      t.index :token_digest, unique: true
    end
  end
end
