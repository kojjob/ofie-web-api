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

  test "can_message? should return true for any user" do
    user = create(:user, :tenant)
    assert @bot.can_message?(user)
  end

  test "can_start_conversation_with? should return true for any user" do
    user = create(:user, :tenant)
    assert @bot.can_start_conversation_with?(user)
  end

  test "primary_bot should return the first bot" do
    primary = Bot.primary_bot
    assert_equal @bot, primary
  end

  test "create_primary_bot should create a bot if none exists" do
    Bot.destroy_all
    bot = Bot.create_primary_bot

    assert bot.persisted?
    assert_equal "bot", bot.role
    assert_equal "Ofie Assistant", bot.name
  end

  test "create_primary_bot should return existing bot if one exists" do
    existing_bot = Bot.create_primary_bot
    assert_equal @bot, existing_bot
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

  test "should scope active bots" do
    inactive_bot = Bot.create!(
      name: "Inactive Bot",
      email: "inactive@example.com",
      password: "password123",
      role: "bot",
      active: false
    )

    active_bots = Bot.active
    assert_includes active_bots, @bot
    assert_not_includes active_bots, inactive_bot
  end
end
