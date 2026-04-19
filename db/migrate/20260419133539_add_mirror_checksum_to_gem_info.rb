class AddMirrorChecksumToGemInfo < ActiveRecord::Migration[8.1]
  def change
    add_column :namespace_gem_infos, :mirror_checksum, :string
  end
end
