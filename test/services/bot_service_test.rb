require "test_helper"

class BotServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:tenant_user)
    @landlord = users(:landlord_user)
    @property = properties(:sample_property)
    @conversation = conversations(:sample_conversation)
    @bot_service = BotService.new(
      user: @user,
      query: "Hello, I need help",
      conversation: @conversation
    )
  end

  test "should initialize with user, query, and conversation" do
    assert_equal @user, @bot_service.instance_variable_get(:@user)
    assert_equal "Hello, I need help", @bot_service.instance_variable_get(:@query)
    assert_equal @conversation, @bot_service.instance_variable_get(:@conversation)
  end

  test "process_query should return response hash" do
    response = @bot_service.process_query

    assert response.is_a?(Hash)
    assert response.key?(:response)
    assert response.key?(:intent)
    assert response.key?(:confidence)
    assert response.key?(:quick_actions)
  end

  test "should classify greeting intent" do
    service = BotService.new(
      user: @user,
      query: "Hello there!",
      conversation: @conversation
    )

    response = service.process_query
    assert_equal "greeting", response[:intent]
  end

  test "should classify property search intent" do
    service = BotService.new(
      user: @user,
      query: "Find me a 2 bedroom apartment",
      conversation: @conversation
    )

    response = service.process_query
    assert_equal "property_search", response[:intent]
  end

  test "should classify rental application intent" do
    service = BotService.new(
      user: @user,
      query: "How do I apply for this rental?",
      conversation: @conversation
    )

    response = service.process_query
    assert_equal "rental_application", response[:intent]
  end

  test "should classify maintenance request intent" do
    service = BotService.new(
      user: @user,
      query: "My sink is broken",
      conversation: @conversation
    )

    response = service.process_query
    assert_equal "maintenance_request", response[:intent]
  end

  test "should classify payment intent" do
    service = BotService.new(
      user: @user,
      query: "How do I pay my rent?",
      conversation: @conversation
    )

    response = service.process_query
    assert_equal "payment", response[:intent]
  end

  test "should provide different responses for tenants vs landlords" do
    tenant_service = BotService.new(
      user: @user,
      query: "How do I list a property?",
      conversation: @conversation
    )

    landlord_service = BotService.new(
      user: @landlord,
      query: "How do I list a property?",
      conversation: @conversation
    )

    tenant_response = tenant_service.process_query
    landlord_response = landlord_service.process_query

    assert_not_equal tenant_response[:response], landlord_response[:response]
  end

  test "should include quick actions in response" do
    response = @bot_service.process_query

    assert response[:quick_actions].is_a?(Array)
    assert response[:quick_actions].length > 0
  end

  test "should handle empty query gracefully" do
    service = BotService.new(
      user: @user,
      query: "",
      conversation: @conversation
    )

    response = service.process_query
    assert_equal "greeting", response[:intent]
    assert response[:response].include?("Hello")
  end

  test "should handle unknown queries" do
    service = BotService.new(
      user: @user,
      query: "xyzabc random nonsense",
      conversation: @conversation
    )

    response = service.process_query
    assert_equal "unknown", response[:intent]
    assert response[:response].include?("I'm not sure")
  end

  test "should provide contextual responses based on conversation" do
    # Test that bot considers conversation context
    response = @bot_service.process_query

    # Should include property information if conversation has a property
    if @conversation.property
      assert response[:response].length > 50 # More detailed response
    end
  end

  test "should return appropriate confidence scores" do
    # High confidence for clear intents
    service = BotService.new(
      user: @user,
      query: "Hello",
      conversation: @conversation
    )

    response = service.process_query
    assert response[:confidence] >= 0.8

    # Lower confidence for ambiguous queries
    service = BotService.new(
      user: @user,
      query: "something unclear",
      conversation: @conversation
    )

    response = service.process_query
    assert response[:confidence] < 0.8
  end

  test "should provide role-specific quick actions" do
    tenant_service = BotService.new(
      user: @user,
      query: "Help",
      conversation: @conversation
    )

    landlord_service = BotService.new(
      user: @landlord,
      query: "Help",
      conversation: @conversation
    )

    tenant_response = tenant_service.process_query
    landlord_response = landlord_service.process_query

    # Tenant should see tenant-specific actions
    tenant_actions = tenant_response[:quick_actions].join(" ")
    assert tenant_actions.include?("Apply") || tenant_actions.include?("Search")

    # Landlord should see landlord-specific actions
    landlord_actions = landlord_response[:quick_actions].join(" ")
    assert landlord_actions.include?("List") || landlord_actions.include?("Manage")
  end
end
