# Migration to enhance existing tables for bot functionality
class EnhanceTablesForBotSystem < ActiveRecord::Migration[8.0]
  def change
    # Add preferences column to users table
    add_column :users, :preferences, :json unless column_exists?(:users, :preferences)
    add_column :users, :last_seen_at, :datetime unless column_exists?(:users, :last_seen_at)
    add_index :users, :last_seen_at unless index_exists?(:users, :last_seen_at)

    # Add metadata column to messages table
    add_column :messages, :metadata, :json unless column_exists?(:messages, :metadata)
    add_index :messages, :created_at unless index_exists?(:messages, :created_at)

    # Add metadata column to conversations table
    add_column :conversations, :metadata, :json unless column_exists?(:conversations, :metadata)
    add_index :conversations, :last_message_at unless index_exists?(:conversations, :last_message_at)

    # Add bot-related fields to properties table for recommendations
    add_column :properties, :score, :decimal, precision: 8, scale: 2, default: 0.0 unless column_exists?(:properties, :score)
    add_column :properties, :views_count, :integer, default: 0 unless column_exists?(:properties, :views_count)
    add_column :properties, :applications_count, :integer, default: 0 unless column_exists?(:properties, :applications_count)
    add_column :properties, :favorites_count, :integer, default: 0 unless column_exists?(:properties, :favorites_count)

    add_index :properties, :score unless index_exists?(:properties, :score)
    add_index :properties, [ :score, :created_at ] unless index_exists?(:properties, [ :score, :created_at ])
    add_index :properties, [ :city, :property_type ] unless index_exists?(:properties, [ :city, :property_type ])
    add_index :properties, [ :price, :bedrooms, :bathrooms ] unless index_exists?(:properties, [ :price, :bedrooms, :bathrooms ])
  end
end
