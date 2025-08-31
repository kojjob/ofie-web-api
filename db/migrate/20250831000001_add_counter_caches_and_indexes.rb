class AddCounterCachesAndIndexes < ActiveRecord::Migration[7.0]
  def up
    # Add counter cache columns to users table
    add_column :users, :properties_count, :integer, default: 0, null: false
    
    # Add counter cache columns to properties table (some may already exist)
    add_column :properties, :comments_count, :integer, default: 0, null: false unless column_exists?(:properties, :comments_count)
    add_column :properties, :reviews_count, :integer, default: 0, null: false unless column_exists?(:properties, :reviews_count)
    
    # Add counter cache columns to property_comments table
    add_column :property_comments, :replies_count, :integer, default: 0, null: false
    
    # Add database indexes for better query performance
    add_index :properties, [:user_id, :availability_status], name: 'index_properties_on_user_and_status'
    add_index :properties, [:city, :availability_status], name: 'index_properties_on_city_and_status'
    add_index :properties, [:property_type, :availability_status], name: 'index_properties_on_type_and_status'
    add_index :properties, [:price, :availability_status], name: 'index_properties_on_price_and_status'
    add_index :properties, [:bedrooms, :bathrooms, :availability_status], name: 'index_properties_on_bed_bath_status'
    
    add_index :property_comments, [:property_id, :parent_id], name: 'index_property_comments_on_property_and_parent'
    add_index :property_comments, [:user_id, :created_at], name: 'index_property_comments_on_user_and_created'
    add_index :property_comments, [:property_id, :flagged, :created_at], name: 'index_property_comments_on_property_flagged_created'
    
    add_index :property_favorites, [:user_id, :created_at], name: 'index_property_favorites_on_user_and_created'
    add_index :property_viewings, [:user_id, :scheduled_at], name: 'index_property_viewings_on_user_and_scheduled'
    add_index :property_reviews, [:property_id, :rating], name: 'index_property_reviews_on_property_and_rating'
    
    add_index :comment_likes, [:property_comment_id, :user_id], name: 'index_comment_likes_on_comment_and_user', unique: true
    
    # Initialize counter caches manually
    say_with_time "Initializing counter caches..." do
      # Update properties_count for users
      execute <<-SQL
        UPDATE users SET properties_count = (
          SELECT COUNT(*) FROM properties WHERE properties.user_id = users.id
        )
      SQL

      # Update comments_count for properties
      execute <<-SQL
        UPDATE properties SET comments_count = (
          SELECT COUNT(*) FROM property_comments WHERE property_comments.property_id = properties.id
        )
      SQL

      # Update reviews_count for properties
      execute <<-SQL
        UPDATE properties SET reviews_count = (
          SELECT COUNT(*) FROM property_reviews WHERE property_reviews.property_id = properties.id
        )
      SQL

      # Update replies_count for property_comments
      execute <<-SQL
        UPDATE property_comments SET replies_count = (
          SELECT COUNT(*) FROM property_comments replies WHERE replies.parent_id = property_comments.id
        )
      SQL
    end
  end

  def down
    # Remove counter cache columns
    remove_column :users, :properties_count if column_exists?(:users, :properties_count)
    remove_column :properties, :comments_count if column_exists?(:properties, :comments_count)
    remove_column :properties, :reviews_count if column_exists?(:properties, :reviews_count)
    remove_column :property_comments, :replies_count if column_exists?(:property_comments, :replies_count)
    
    # Remove indexes
    remove_index :properties, name: 'index_properties_on_user_and_status' if index_exists?(:properties, name: 'index_properties_on_user_and_status')
    remove_index :properties, name: 'index_properties_on_city_and_status' if index_exists?(:properties, name: 'index_properties_on_city_and_status')
    remove_index :properties, name: 'index_properties_on_type_and_status' if index_exists?(:properties, name: 'index_properties_on_type_and_status')
    remove_index :properties, name: 'index_properties_on_price_and_status' if index_exists?(:properties, name: 'index_properties_on_price_and_status')
    remove_index :properties, name: 'index_properties_on_bed_bath_status' if index_exists?(:properties, name: 'index_properties_on_bed_bath_status')
    
    remove_index :property_comments, name: 'index_property_comments_on_property_and_parent' if index_exists?(:property_comments, name: 'index_property_comments_on_property_and_parent')
    remove_index :property_comments, name: 'index_property_comments_on_user_and_created' if index_exists?(:property_comments, name: 'index_property_comments_on_user_and_created')
    remove_index :property_comments, name: 'index_property_comments_on_property_flagged_created' if index_exists?(:property_comments, name: 'index_property_comments_on_property_flagged_created')
    
    remove_index :property_favorites, name: 'index_property_favorites_on_user_and_created' if index_exists?(:property_favorites, name: 'index_property_favorites_on_user_and_created')
    remove_index :property_viewings, name: 'index_property_viewings_on_user_and_scheduled' if index_exists?(:property_viewings, name: 'index_property_viewings_on_user_and_scheduled')
    remove_index :property_reviews, name: 'index_property_reviews_on_property_and_rating' if index_exists?(:property_reviews, name: 'index_property_reviews_on_property_and_rating')
    
    remove_index :comment_likes, name: 'index_comment_likes_on_comment_and_user' if index_exists?(:comment_likes, name: 'index_comment_likes_on_comment_and_user')
  end
end
