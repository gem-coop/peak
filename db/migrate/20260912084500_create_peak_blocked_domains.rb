class CreatePeakBlockedDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :peak_blocked_domains do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :source, null: false, default: "manual"

      t.timestamps
    end

    add_index :peak_blocked_domains, [:source, :updated_at]
  end
end
