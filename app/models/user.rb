class User < ApplicationRecord
  has_secure_password # Provides password hashing and authentication methods
  has_many :properties, dependent: :destroy

  # Define roles as an enum for easy management and validation
  enum :role, { tenant: "tenant", landlord: "landlord" }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create # only validate on create
  validates :role, presence: true, inclusion: { in: roles.keys } # Ensure valid role

  # JWT encoding/decoding helper
  def self.encode_token(payload)
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode_token(token)
    JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
  rescue JWT::DecodeError
    nil # Handle invalid token
  end
end
