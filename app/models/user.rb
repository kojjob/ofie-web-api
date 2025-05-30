class User < ApplicationRecord
  has_secure_password # Provides password hashing and authentication methods
  has_many :properties, dependent: :destroy

  # New associations for property features
  has_many :property_favorites, dependent: :destroy
  has_many :favorite_properties, through: :property_favorites, source: :property
  has_many :property_viewings, dependent: :destroy
  has_many :property_reviews, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Messaging associations
  has_many :landlord_conversations, class_name: "Conversation", foreign_key: "landlord_id", dependent: :destroy
  has_many :tenant_conversations, class_name: "Conversation", foreign_key: "tenant_id", dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy

  # Payment and rental associations
  has_many :payment_methods, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :tenant_rental_applications, class_name: "RentalApplication", foreign_key: "tenant_id", dependent: :destroy
  has_many :reviewed_rental_applications, class_name: "RentalApplication", foreign_key: "reviewed_by_id", dependent: :nullify
  has_many :landlord_lease_agreements, class_name: "LeaseAgreement", foreign_key: "landlord_id", dependent: :destroy
  has_many :tenant_lease_agreements, class_name: "LeaseAgreement", foreign_key: "tenant_id", dependent: :destroy

  # Maintenance request associations
  has_many :tenant_maintenance_requests, class_name: "MaintenanceRequest", foreign_key: "tenant_id", dependent: :destroy
  has_many :landlord_maintenance_requests, class_name: "MaintenanceRequest", foreign_key: "landlord_id", dependent: :destroy
  has_many :assigned_maintenance_requests, class_name: "MaintenanceRequest", foreign_key: "assigned_to_id", dependent: :nullify

  # Define roles as an enum for easy management and validation
  enum :role, { tenant: "tenant", landlord: "landlord" }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create, unless: :oauth_user?
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :provider, presence: true, if: :oauth_user?
  validates :uid, presence: true, if: :oauth_user?
  validates :stripe_customer_id, uniqueness: true, allow_nil: true

  # Callbacks
  before_create :generate_email_verification_token
  after_create :send_email_verification, unless: :oauth_user?

  # JWT encoding/decoding helper
  def self.encode_token(payload, expires_in = 24.hours)
    payload[:exp] = expires_in.from_now.to_i
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode_token(token)
    JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
  rescue JWT::DecodeError
    nil # Handle invalid token
  end

  # Generate refresh token
  def generate_refresh_token
    self.refresh_token = SecureRandom.hex(32)
    self.refresh_token_expires_at = 30.days.from_now
    save!
    refresh_token
  end

  # Check if refresh token is valid
  def refresh_token_valid?
    refresh_token.present? && refresh_token_expires_at > Time.current
  end

  # Generate password reset token
  def generate_password_reset_token
    self.password_reset_token = SecureRandom.urlsafe_base64(32)
    self.password_reset_sent_at = Time.current
    save!
  end

  # Check if password reset token is valid (expires in 2 hours)
  def password_reset_token_valid?
    password_reset_token.present? && password_reset_sent_at > 2.hours.ago
  end

  # Generate email verification token
  def generate_email_verification_token
    self.email_verification_token = SecureRandom.urlsafe_base64(32)
    self.email_verification_sent_at = Time.current
  end

  # Check if email verification token is valid (expires in 24 hours)
  def email_verification_token_valid?
    email_verification_token.present? && email_verification_sent_at > 24.hours.ago
  end

  # Verify email
  def verify_email!
    self.email_verified = true
    self.email_verification_token = nil
    self.email_verification_sent_at = nil
    save!
  end

  # Check if user is OAuth user
  def oauth_user?
    provider.present? && uid.present?
  end

  # Find or create user from OAuth data
  def self.from_oauth(auth_hash)
    user = find_by(provider: auth_hash.provider, uid: auth_hash.uid)

    if user
      user
    else
      # Try to find existing user by email
      existing_user = find_by(email: auth_hash.info.email)

      if existing_user
        # Link OAuth account to existing user
        existing_user.update!(
          provider: auth_hash.provider,
          uid: auth_hash.uid,
          email_verified: true
        )
        existing_user
      else
        # Create new user
        create!(
          email: auth_hash.info.email,
          provider: auth_hash.provider,
          uid: auth_hash.uid,
          email_verified: true,
          role: "tenant" # Default role for OAuth users
        )
      end
    end
  end

  # Messaging helper methods
  def conversations
    Conversation.where("landlord_id = ? OR tenant_id = ?", id, id)
  end

  def unread_messages_count
    conversations.sum { |conv| conv.unread_count_for(self) }
  end

  def conversation_with(other_user, property)
    conversations.find_by(
      landlord: landlord?(other_user) ? other_user : self,
      tenant: tenant?(other_user) ? other_user : self,
      property: property
    )
  end

  def can_message?(other_user, property)
    return false if self == other_user
    return false unless property

    # Landlords can message tenants, tenants can message landlords
    (landlord? && other_user.tenant?) || (tenant? && other_user.landlord?)
  end


  def landlord?(user = self)
    user.role == "landlord"
  end

  def tenant?(user = self)
    user.role == "tenant"
  end

  private

  def send_email_verification
    UserMailer.email_verification(self).deliver_now
  rescue => e
    Rails.logger.error "Failed to send email verification: #{e.message}"
  end
end
