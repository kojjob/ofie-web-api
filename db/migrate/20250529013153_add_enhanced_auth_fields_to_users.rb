class AddEnhancedAuthFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_verified, :boolean, default: false, null: false
    add_column :users, :email_verification_token, :string
    add_column :users, :email_verification_sent_at, :datetime
    add_column :users, :password_reset_token, :string
    add_column :users, :password_reset_sent_at, :datetime
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :refresh_token, :string
    add_column :users, :refresh_token_expires_at, :datetime

    # Add indexes for performance
    add_index :users, :email_verification_token, unique: true
    add_index :users, :password_reset_token, unique: true
    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, :refresh_token, unique: true
  end
end
