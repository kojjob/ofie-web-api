class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.string :address, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip_code, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :bedrooms, null: false
      t.decimal :bathrooms, precision: 3, scale: 1, null: false
      t.integer :square_feet
      t.string :property_type, null: false
      t.boolean :available, default: true, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :properties, :city
    add_index :properties, :state
    add_index :properties, :property_type
    add_index :properties, :available
    add_index :properties, :price
  end
end
