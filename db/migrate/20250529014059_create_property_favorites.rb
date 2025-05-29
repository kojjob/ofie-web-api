class CreatePropertyFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :property_favorites do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :property, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :property_favorites, [ :user_id, :property_id ], unique: true, if_not_exists: true
    add_index :property_favorites, :property_id, if_not_exists: true
  end
end
