class CreatePeakTermsAcceptances < ActiveRecord::Migration[8.1]
  def change
    create_table :peak_terms_acceptances do |t|
      t.references :terms, index: true, null: false
      t.references :user, index: true, null: false
      t.string :sha, null: false
      t.datetime :captured_at, null: false
      t.string :time_zone, null: false
      t.boolean :accepted, null: false, default: false

      t.timestamps
    end
  end
end
