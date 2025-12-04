require "test_helper"

class BotTest < ActiveSupport::TestCase
  def setup
    @bot = Bot.create!(
      name: "Test Bot",
      email: "testbot@example.com",
      password: "password123",
      role: "bot"
    )
  end

  test "should be valid with valid attributes" do
    assert @bot.valid?
  end

  test "should inherit from User" do
    assert @bot.is_a?(User)
  end

  test "should have bot role" do
    assert_equal "bot", @bot.role
  end

  test "bot? should return true" do
    assert @bot.bot?
  end

  test "human? should return false" do
    assert_not @bot.human?
  end

  test "should be available for chat by default" do
    assert @bot.available_for_chat?
  end

  test "can_message? should return true for verified user" do
    user = create(:user, :tenant, :verified)
    assert @bot.can_message?(user)
  end

  test "can_message? should return false for unverified user" do
    user = create(:user, :tenant)
    assert_not @bot.can_message?(user)
  end

  test "can_start_conversation_with? should return true for verified user" do
    user = create(:user, :tenant, :verified)
    assert @bot.can_start_conversation_with?(user)
  end

  test "can_start_conversation_with? should return false for unverified user" do
    user = create(:user, :tenant)
    assert_not @bot.can_start_conversation_with?(user)
  end

  test "primary_bot should return the bot with email bot@ofie.com" do
    primary = Bot.primary_bot
    assert_equal "bot@ofie.com", primary.email
    assert_equal "Ofie Assistant", primary.name
  end

  test "create_primary_bot should create a bot if none exists" do
    Bot.destroy_all
    bot = Bot.create_primary_bot

    assert bot.persisted?
    assert_equal "bot", bot.role
    assert_equal "Ofie Assistant", bot.name
  end

  test "create_primary_bot should return bot with standard email" do
    # Clean up any existing primary bot
    Bot.find_by(email: "bot@ofie.com")&.destroy

    # First call creates the primary bot
    first_bot = Bot.create_primary_bot
    assert_equal "bot@ofie.com", first_bot.email

    # Second call should return the same bot (via primary_bot which finds by email)
    second_bot = Bot.primary_bot
    assert_equal first_bot.id, second_bot.id
  end

  test "should validate presence of name" do
    @bot.name = nil
    assert_not @bot.valid?
    assert_includes @bot.errors[:name], "can't be blank"
  end

  test "should validate presence of email" do
    @bot.email = nil
    assert_not @bot.valid?
    assert_includes @bot.errors[:email], "can't be blank"
  end

  test "should validate uniqueness of email" do
    duplicate_bot = Bot.new(
      name: "Another Bot",
      email: @bot.email,
      password: "password123",
      role: "bot"
    )

    assert_not duplicate_bot.valid?
    assert_includes duplicate_bot.errors[:email], "has already been taken"
  end

  test "should scope active_bots based on email_verified" do
    # Note: Bot's before_create callback sets email_verified = true
    # So we need to manually update a bot to test the scope

    # Create a bot (will have email_verified: true due to callback)
    verified_bot = Bot.create!(
      name: "Verified Bot",
      email: "verified@example.com",
      password: "password123",
      role: "bot"
    )

    # Create another bot and manually set email_verified to false
    unverified_bot = Bot.create!(
      name: "Unverified Bot",
      email: "unverified@example.com",
      password: "password123",
      role: "bot"
    )
    unverified_bot.update_column(:email_verified, false)

    active_bots = Bot.active_bots
    assert_includes active_bots, verified_bot
    assert_not_includes active_bots, unverified_bot
  end
end
