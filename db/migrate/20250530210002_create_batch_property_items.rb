class CreateBatchPropertyItems < ActiveRecord::Migration[8.0]
  def change
    create_table :batch_property_items, id: :uuid do |t|
      t.references :batch_property_upload, null: false, foreign_key: true, type: :uuid, index: true
      t.references :property, null: true, foreign_key: true, type: :uuid, index: true
      t.integer :row_number, null: false
      t.text :property_data, null: false
      t.string :status, null: false, default: 'pending'
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    # Add indexes for better query performance
    add_index :batch_property_items, :status
    add_index :batch_property_items, :row_number
    add_index :batch_property_items, [ :batch_property_upload_id, :status ]
    add_index :batch_property_items, [ :batch_property_upload_id, :row_number ]
  end
end
