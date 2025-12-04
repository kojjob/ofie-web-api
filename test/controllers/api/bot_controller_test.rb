require "test_helper"

class Api::BotControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user, :tenant, :verified)
    @landlord = create(:user, :landlord, :verified)
    @property = create(:property, user: @landlord)
    @conversation = create(:conversation, landlord: @landlord, tenant: @user, property: @property)
    @bot = Bot.create!(
      name: "Test Bot",
      email: "testbot@example.com",
      password: "password123",
      role: "bot"
    )

    # Mock authentication
    @headers = {
      "Authorization" => "Bearer #{generate_jwt_token(@user)}",
      "Content-Type" => "application/json"
    }
  end

  test "POST /api/v1/bot/chat should return bot response" do
    post "/api/v1/bot/chat",
         params: { query: "Hello, I need help" }.to_json,
         headers: @headers

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("conversation_id")
    assert json_response.key?("message")
    assert json_response.key?("intent")
    assert json_response.key?("quick_actions")
    assert json_response.key?("confidence")

    message = json_response["message"]
    assert message.key?("id")
    assert message.key?("content")
    assert message.key?("sender")
    assert message.key?("created_at")

    sender = message["sender"]
    assert_equal @bot.id, sender["id"]
    assert_equal @bot.name, sender["name"]
    assert_equal "bot", sender["role"]
  end

  test "POST /api/v1/bot/chat with existing conversation should use existing conversation" do
    post "/api/v1/bot/chat",
         params: {
           query: "Hello",
           conversation_id: @conversation.id
         }.to_json,
         headers: @headers

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal @conversation.id, json_response["conversation_id"]
  end

  test "POST /api/v1/bot/chat should return error for blank query" do
    post "/api/v1/bot/chat",
         params: { query: "" }.to_json,
         headers: @headers

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert json_response.key?("error")
    assert_equal "Query cannot be blank", json_response["error"]
  end

  test "POST /api/v1/bot/start_conversation should create new conversation" do
    post "/api/v1/bot/start_conversation",
         params: {
           property_id: @property.id,
           message: "I'm interested in this property"
         }.to_json,
         headers: @headers

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("conversation_id")
    assert json_response.key?("message")
    assert json_response.key?("redirect_url")

    # Verify conversation was created
    conversation = Conversation.find(json_response["conversation_id"])
    assert_equal @property, conversation.property
    assert conversation.tenant == @user || conversation.landlord == @user
  end

  test "GET /api/v1/bot/suggestions should return role-specific suggestions" do
    get "/api/v1/bot/suggestions", headers: @headers

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("suggestions")
    assert json_response["suggestions"].is_a?(Array)
    assert json_response["suggestions"].length > 0

    # Should contain tenant-specific suggestions
    suggestions_text = json_response["suggestions"].join(" ")
    assert suggestions_text.include?("apply") || suggestions_text.include?("find")
  end

  test "GET /api/v1/bot/suggestions for landlord should return landlord suggestions" do
    landlord_headers = {
      "Authorization" => "Bearer #{generate_jwt_token(@landlord)}",
      "Content-Type" => "application/json"
    }

    get "/api/v1/bot/suggestions", headers: landlord_headers

    assert_response :success

    json_response = JSON.parse(response.body)
    suggestions_text = json_response["suggestions"].join(" ")
    assert suggestions_text.include?("list") || suggestions_text.include?("manage")
  end

  test "GET /api/v1/bot/faqs should return FAQs and tips" do
    get "/api/v1/bot/faqs", headers: @headers

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("faqs")
    assert json_response.key?("tips")
    assert json_response["faqs"].is_a?(Array)
    assert json_response["tips"].is_a?(Array)
  end

  test "POST /api/v1/bot/feedback should accept feedback" do
    message = @conversation.messages.create!(
      sender: @bot,
      content: "Test message",
      message_type: "text"
    )

    post "/api/v1/bot/feedback",
         params: {
           message_id: message.id,
           rating: 5,
           comment: "Very helpful!"
         }.to_json,
         headers: @headers

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("message")
    assert_equal "Thank you for your feedback!", json_response["message"]
  end

  test "should require authentication for all endpoints" do
    # Test without authorization header
    post "/api/v1/bot/chat",
         params: { query: "Hello" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized

    get "/api/v1/bot/suggestions"
    assert_response :unauthorized

    get "/api/v1/bot/faqs"
    assert_response :unauthorized
  end

  test "should return service unavailable when bot is not available" do
    # Remove all bots
    Bot.destroy_all

    post "/api/v1/bot/chat",
         params: { query: "Hello" }.to_json,
         headers: @headers

    assert_response :service_unavailable

    json_response = JSON.parse(response.body)
    assert_equal "Bot service unavailable", json_response["error"]
  end

  test "should handle internal server errors gracefully" do
    # Mock BotService to raise an error
    BotService.any_instance.stubs(:process_query).raises(StandardError.new("Test error"))

    post "/api/v1/bot/chat",
         params: { query: "Hello" }.to_json,
         headers: @headers

    assert_response :internal_server_error

    json_response = JSON.parse(response.body)
    assert json_response.key?("error")
    assert_equal "Something went wrong. Please try again.", json_response["error"]
  end

  private

  def generate_jwt_token(user)
    # Mock JWT token generation - replace with actual implementation
    payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end
