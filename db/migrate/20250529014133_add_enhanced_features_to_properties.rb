class AddEnhancedFeaturesToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :parking_available, :boolean
    add_column :properties, :pets_allowed, :boolean
    add_column :properties, :furnished, :boolean
    add_column :properties, :utilities_included, :boolean
    add_column :properties, :laundry, :boolean
    add_column :properties, :gym, :boolean
    add_column :properties, :pool, :boolean
    add_column :properties, :balcony, :boolean
    add_column :properties, :air_conditioning, :boolean
    add_column :properties, :heating, :boolean
    add_column :properties, :internet_included, :boolean
    add_column :properties, :status, :integer
  end
end
