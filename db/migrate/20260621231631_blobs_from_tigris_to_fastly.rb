class BlobsFromTigrisToFastly < ActiveRecord::Migration[8.1]
  def change
    ActiveStorage::Blob.where(service_name: "tigris").update_all(service_name: "fastly")
  end
end
