class CreatePropertyViewings < ActiveRecord::Migration[8.0]
  def change
    create_table :property_viewings do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :property, null: false, foreign_key: true, type: :uuid
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false
      t.text :notes
      t.string :contact_phone
      t.string :contact_email

      t.timestamps
    end

    add_index :property_viewings, [ :user_id, :scheduled_at ]
    add_index :property_viewings, [ :property_id, :scheduled_at ]
    add_index :property_viewings, :status
  end
end
