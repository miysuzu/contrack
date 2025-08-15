class RemoveAndAddCascadeToActiveStorageAttachments < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :active_storage_attachments, :active_storage_blobs
    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id, on_delete: :cascade
  end
end
