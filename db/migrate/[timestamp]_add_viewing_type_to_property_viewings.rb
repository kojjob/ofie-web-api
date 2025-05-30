class AddViewingTypeToPropertyViewings < ActiveRecord::Migration[8.0]
  def change
    add_column :property_viewings, :viewing_type, :integer, default: 0, null: false
    add_index :property_viewings, :viewing_type
  end
end
