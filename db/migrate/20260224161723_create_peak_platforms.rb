class CreatePeakPlatforms < ActiveRecord::Migration[8.1]
  def change
    create_table :peak_platforms do |t|
      t.string :key, index: { unique: true, name: "peak_platforms_uniqueness" }
      t.string :arch, null: false
      t.string :name, null: false
      t.string :specifier, null: false
      t.boolean :precompile_target, null: false, default: false

      t.timestamps
    end
  end
end
