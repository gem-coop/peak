class CreatePeakEmailAddressDisposedDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :peak_email_address_disposed_domains do |t|
      t.string :name, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
