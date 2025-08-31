class AddPerformanceIndexes < ActiveRecord::Migration[7.0]
  def change
    # Property indexes for search and filtering
    add_index :properties, [:status, :created_at], name: 'index_properties_on_status_and_created_at'
    add_index :properties, [:user_id, :status], name: 'index_properties_on_user_id_and_status'
    add_index :properties, :location, name: 'index_properties_on_location'
    add_index :properties, :price, name: 'index_properties_on_price'
    add_index :properties, [:bedrooms, :bathrooms], name: 'index_properties_on_bedrooms_and_bathrooms'
    add_index :properties, :property_type, name: 'index_properties_on_property_type'
    add_index :properties, :featured, name: 'index_properties_on_featured'
    
    # Property favorites composite index for uniqueness and lookups
    add_index :property_favorites, [:user_id, :property_id], 
              unique: true, 
              name: 'index_property_favorites_on_user_and_property'
    
    # Property viewings indexes
    add_index :property_viewings, [:user_id, :property_id], 
              name: 'index_property_viewings_on_user_and_property'
    add_index :property_viewings, :viewing_date, 
              name: 'index_property_viewings_on_viewing_date'
    
    # Property reviews indexes
    add_index :property_reviews, [:property_id, :rating], 
              name: 'index_property_reviews_on_property_and_rating'
    add_index :property_reviews, [:user_id, :created_at], 
              name: 'index_property_reviews_on_user_and_created_at'
    
    # Payments indexes for financial queries
    add_index :payments, [:user_id, :status], 
              name: 'index_payments_on_user_id_and_status'
    add_index :payments, [:lease_agreement_id, :status], 
              name: 'index_payments_on_lease_agreement_and_status'
    add_index :payments, [:status, :due_date], 
              name: 'index_payments_on_status_and_due_date'
    add_index :payments, :processed_at, 
              name: 'index_payments_on_processed_at'
    
    # Lease agreements indexes
    add_index :lease_agreements, [:property_id, :status], 
              name: 'index_lease_agreements_on_property_and_status'
    add_index :lease_agreements, [:tenant_id, :status], 
              name: 'index_lease_agreements_on_tenant_and_status'
    add_index :lease_agreements, [:landlord_id, :status], 
              name: 'index_lease_agreements_on_landlord_and_status'
    add_index :lease_agreements, [:start_date, :end_date], 
              name: 'index_lease_agreements_on_dates'
    
    # Maintenance requests indexes
    add_index :maintenance_requests, [:property_id, :status], 
              name: 'index_maintenance_requests_on_property_and_status'
    add_index :maintenance_requests, [:tenant_id, :created_at], 
              name: 'index_maintenance_requests_on_tenant_and_created_at'
    add_index :maintenance_requests, :priority, 
              name: 'index_maintenance_requests_on_priority'
    
    # Notifications indexes
    add_index :notifications, [:user_id, :read], 
              name: 'index_notifications_on_user_and_read'
    add_index :notifications, [:user_id, :created_at], 
              name: 'index_notifications_on_user_and_created_at'
    
    # Messages and conversations indexes
    add_index :messages, [:conversation_id, :created_at], 
              name: 'index_messages_on_conversation_and_created_at'
    add_index :messages, [:sender_id, :read], 
              name: 'index_messages_on_sender_and_read'
    
    add_index :conversations, [:landlord_id, :tenant_id], 
              name: 'index_conversations_on_landlord_and_tenant'
    add_index :conversations, [:property_id, :created_at], 
              name: 'index_conversations_on_property_and_created_at'
    
    # User indexes for authentication and lookups
    add_index :users, :email, unique: true, name: 'index_users_on_email' unless index_exists?(:users, :email)
    add_index :users, :role, name: 'index_users_on_role'
    add_index :users, :stripe_customer_id, name: 'index_users_on_stripe_customer_id'
    add_index :users, [:provider, :uid], name: 'index_users_on_provider_and_uid'
    
    # Full-text search indexes (PostgreSQL specific)
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      # Enable pg_trgm extension for trigram search
      enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
      
      # Add GIN indexes for full-text search
      execute <<-SQL
        CREATE INDEX IF NOT EXISTS index_properties_on_title_gin 
        ON properties USING gin(title gin_trgm_ops);
        
        CREATE INDEX IF NOT EXISTS index_properties_on_description_gin 
        ON properties USING gin(description gin_trgm_ops);
        
        CREATE INDEX IF NOT EXISTS index_properties_on_address_gin 
        ON properties USING gin(address gin_trgm_ops);
        
        CREATE INDEX IF NOT EXISTS index_properties_on_location_gin 
        ON properties USING gin(location gin_trgm_ops);
      SQL
      
      # Add composite full-text search index
      execute <<-SQL
        CREATE INDEX IF NOT EXISTS index_properties_full_text_search
        ON properties USING gin(
          to_tsvector('english', 
            coalesce(title, '') || ' ' || 
            coalesce(description, '') || ' ' || 
            coalesce(address, '') || ' ' || 
            coalesce(location, '')
          )
        );
      SQL
    end
  end
  
  def down
    # Remove all indexes in reverse order
    remove_index :properties, name: 'index_properties_on_status_and_created_at'
    remove_index :properties, name: 'index_properties_on_user_id_and_status'
    remove_index :properties, name: 'index_properties_on_location'
    remove_index :properties, name: 'index_properties_on_price'
    remove_index :properties, name: 'index_properties_on_bedrooms_and_bathrooms'
    remove_index :properties, name: 'index_properties_on_property_type'
    remove_index :properties, name: 'index_properties_on_featured'
    
    remove_index :property_favorites, name: 'index_property_favorites_on_user_and_property'
    remove_index :property_viewings, name: 'index_property_viewings_on_user_and_property'
    remove_index :property_viewings, name: 'index_property_viewings_on_viewing_date'
    remove_index :property_reviews, name: 'index_property_reviews_on_property_and_rating'
    remove_index :property_reviews, name: 'index_property_reviews_on_user_and_created_at'
    
    remove_index :payments, name: 'index_payments_on_user_id_and_status'
    remove_index :payments, name: 'index_payments_on_lease_agreement_and_status'
    remove_index :payments, name: 'index_payments_on_status_and_due_date'
    remove_index :payments, name: 'index_payments_on_processed_at'
    
    remove_index :lease_agreements, name: 'index_lease_agreements_on_property_and_status'
    remove_index :lease_agreements, name: 'index_lease_agreements_on_tenant_and_status'
    remove_index :lease_agreements, name: 'index_lease_agreements_on_landlord_and_status'
    remove_index :lease_agreements, name: 'index_lease_agreements_on_dates'
    
    remove_index :maintenance_requests, name: 'index_maintenance_requests_on_property_and_status'
    remove_index :maintenance_requests, name: 'index_maintenance_requests_on_tenant_and_created_at'
    remove_index :maintenance_requests, name: 'index_maintenance_requests_on_priority'
    
    remove_index :notifications, name: 'index_notifications_on_user_and_read'
    remove_index :notifications, name: 'index_notifications_on_user_and_created_at'
    
    remove_index :messages, name: 'index_messages_on_conversation_and_created_at'
    remove_index :messages, name: 'index_messages_on_sender_and_read'
    
    remove_index :conversations, name: 'index_conversations_on_landlord_and_tenant'
    remove_index :conversations, name: 'index_conversations_on_property_and_created_at'
    
    remove_index :users, name: 'index_users_on_role'
    remove_index :users, name: 'index_users_on_stripe_customer_id'
    remove_index :users, name: 'index_users_on_provider_and_uid'
    
    # Remove PostgreSQL-specific indexes
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute "DROP INDEX IF EXISTS index_properties_on_title_gin;"
      execute "DROP INDEX IF EXISTS index_properties_on_description_gin;"
      execute "DROP INDEX IF EXISTS index_properties_on_address_gin;"
      execute "DROP INDEX IF EXISTS index_properties_on_location_gin;"
      execute "DROP INDEX IF EXISTS index_properties_full_text_search;"
    end
  end
end