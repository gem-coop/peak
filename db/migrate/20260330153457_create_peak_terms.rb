class CreatePeakTerms < ActiveRecord::Migration[8.1]
  def change
    create_table :peak_terms do |t|
      t.text :content, null: false
      t.string :status, null: false, default: :drafted
      t.timestamps
    end
  end
end
