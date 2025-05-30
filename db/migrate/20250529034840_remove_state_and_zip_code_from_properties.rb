class RemoveStateAndZipCodeFromProperties < ActiveRecord::Migration[8.0]
  def change
    remove_column :properties, :state, :string
    remove_column :properties, :zip_code, :string
  end
end
