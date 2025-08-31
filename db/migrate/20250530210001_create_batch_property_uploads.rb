class CreateBatchPropertyUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :batch_property_uploads, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: true
      t.string :filename, null: false
      t.string :status, null: false, default: 'pending'
      t.integer :total_items, default: 0
      t.integer :valid_items, default: 0
      t.integer :invalid_items, default: 0
      t.integer :processed_items, default: 0
      t.integer :successful_items, default: 0
      t.integer :failed_items, default: 0
      t.text :error_message
      t.datetime :completed_at

      t.timestamps
    end

    # Add indexes for better query performance
    add_index :batch_property_uploads, :status
    add_index :batch_property_uploads, :created_at
    add_index :batch_property_uploads, [ :user_id, :status ]
    add_index :batch_property_uploads, [ :user_id, :created_at ]
  end
end
