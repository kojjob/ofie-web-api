class CreateMaintenanceRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_requests, id: :uuid do |t|
      t.uuid :property_id, null: false
      t.uuid :tenant_id, null: false
      t.uuid :landlord_id, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :priority, default: 'medium'
      t.string :status, default: 'pending'
      t.string :category
      t.text :location_details
      t.decimal :estimated_cost, precision: 10, scale: 2
      t.datetime :requested_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :scheduled_at
      t.datetime :completed_at
      t.uuid :assigned_to_id
      t.text :landlord_notes
      t.text :completion_notes
      t.boolean :urgent, default: false
      t.boolean :tenant_present_required, default: false

      t.timestamps
    end

    add_foreign_key :maintenance_requests, :properties, column: :property_id
    add_foreign_key :maintenance_requests, :users, column: :tenant_id
    add_foreign_key :maintenance_requests, :users, column: :landlord_id
    add_foreign_key :maintenance_requests, :users, column: :assigned_to_id

    add_index :maintenance_requests, :property_id
    add_index :maintenance_requests, :tenant_id
    add_index :maintenance_requests, :landlord_id
    add_index :maintenance_requests, :status
    add_index :maintenance_requests, :priority
    add_index :maintenance_requests, :requested_at
    add_index :maintenance_requests, :category
  end
end
