# AI-generated code: Comprehensive Bot model for Ofie rental platform
class Bot < User
  # Bot-specific validations and configurations
  validates :role, inclusion: { in: %w[bot] }

  # Bot should always be verified and active
  before_create :set_bot_defaults

  # Scopes
  scope :active_bots, -> { where(role: "bot", email_verified: true) }

  # Class methods
  def self.primary_bot
    find_by(email: "bot@ofie.com") || create_primary_bot
  end

  def self.create_primary_bot
    create!(
      email: "bot@ofie.com",
      password: SecureRandom.hex(32),
      name: "Ofie Assistant",
      role: "bot",
      bio: "Your helpful AI assistant for all rental platform needs. I can help you find properties, understand rental processes, and navigate the platform.",
      email_verified: true
    )
  end

  # Instance methods
  def can_message?(other_user, property = nil)
    # Bot can message any verified user
    other_user.present? && other_user.email_verified?
  end

  def bot?
    true
  end

  def human?
    false
  end

  def can_start_conversation_with?(user)
    user.present? && user.email_verified? && user != self
  end

  def available_for_chat?
    true # Bot is always available
  end

  private

  def set_bot_defaults
    self.email_verified = true
    self.role = "bot"
  end
end
