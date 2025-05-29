class CreatePropertyReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :property_reviews do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :property, null: false, foreign_key: true, type: :uuid
      t.integer :rating, null: false
      t.string :title, null: false
      t.text :content, null: false
      t.boolean :verified, default: false
      t.integer :helpful_count, default: 0

      t.timestamps
    end

    add_index :property_reviews, [ :user_id, :property_id ], unique: true
    add_index :property_reviews, [ :property_id, :rating ]
    add_index :property_reviews, :verified
    add_check_constraint :property_reviews, "rating >= 1 AND rating <= 5", name: "rating_range_check"
  end
end
