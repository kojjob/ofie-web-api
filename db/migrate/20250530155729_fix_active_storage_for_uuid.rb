class FixActiveStorageForUuid < ActiveRecord::Migration[8.0]
  def up
    # First, clear any existing attachments since they won't be valid with UUID conversion
    execute "DELETE FROM active_storage_attachments"
    execute "DELETE FROM active_storage_blobs"

    # Change record_id from bigint to uuid to support UUID primary keys
    execute "ALTER TABLE active_storage_attachments ALTER COLUMN record_id TYPE uuid USING record_id::text::uuid"
  end

  def down
    # Reverse the change
    change_column :active_storage_attachments, :record_id, :bigint
  end
end
