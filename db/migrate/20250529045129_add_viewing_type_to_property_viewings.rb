class AddViewingTypeToPropertyViewings < ActiveRecord::Migration[8.0]
  def change
    add_column :property_viewings, :viewing_type, :integer
  end
end
