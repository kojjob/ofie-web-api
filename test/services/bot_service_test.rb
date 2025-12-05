require "test_helper"

class BotServiceTest < ActiveSupport::TestCase
  def setup
    @tenant = create(:user, role: "tenant")
    @landlord = create(:user, role: "landlord")
    @property = create(:property, user: @landlord, price: 2000, bedrooms: 2, title: "Modern Apartment")
    @conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)
  end

  # ============================================================================
  # INITIALIZATION TESTS
  # ============================================================================

  test "initializes with user, query, and conversation" do
    bot_service = BotService.new(user: @tenant, query: "Hello", conversation: @conversation)

    assert_equal @tenant, bot_service.instance_variable_get(:@user)
    assert_equal "hello", bot_service.instance_variable_get(:@query) # Query is downcased
    assert_equal @conversation, bot_service.instance_variable_get(:@conversation)
  end

  test "initializes and downcases query" do
    bot_service = BotService.new(user: @tenant, query: "FIND PROPERTIES", conversation: @conversation)

    assert_equal "find properties", bot_service.instance_variable_get(:@query)
  end

  test "initializes with empty context by default" do
    bot_service = BotService.new(user: @tenant, query: "Hello", conversation: @conversation)

    context = bot_service.instance_variable_get(:@context)
    assert_equal({}, context)
  end

  test "initializes with custom context" do
    custom_context = { property_id: @property.id }
    bot_service = BotService.new(user: @tenant, query: "Hello", conversation: @conversation, context: custom_context)

    context = bot_service.instance_variable_get(:@context)
    assert_equal @property.id, context[:property_id]
  end

  # ============================================================================
  # BLANK QUERY HANDLING
  # ============================================================================

  test "returns greeting hash for blank query" do
    bot_service = BotService.new(user: @tenant, query: "", conversation: @conversation)
    response = bot_service.process_query

    assert response.is_a?(Hash)
    assert_equal :greeting, response[:intent]
    assert response[:response].include?("Hello")
    assert response[:response].include?("Ofie assistant")
  end

  test "returns different greeting for tenant vs landlord" do
    tenant_service = BotService.new(user: @tenant, query: "", conversation: @conversation)
    landlord_service = BotService.new(user: @landlord, query: "", conversation: @conversation)

    tenant_response = tenant_service.process_query
    landlord_response = landlord_service.process_query

    assert tenant_response[:response].include?("find properties")
    assert landlord_response[:response].include?("manage your properties")
  end

  # ============================================================================
  # PROCESS_QUERY STRUCTURE TESTS
  # ============================================================================

  test "process_query returns hash with required keys for non-blank query" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)
    response = bot_service.process_query

    assert response.is_a?(Hash)
    assert response.key?(:intent)
    assert response.key?(:response)
    assert response.key?(:quick_actions)
    assert response.key?(:confidence)
  end

  test "process_query intent is a symbol" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)
    response = bot_service.process_query

    assert response[:intent].is_a?(Symbol)
  end

  test "process_query quick_actions is an array" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)
    response = bot_service.process_query

    assert response[:quick_actions].is_a?(Array)
    assert response[:quick_actions].length > 0
  end

  test "process_query confidence is a float" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)
    response = bot_service.process_query

    assert response[:confidence].is_a?(Float)
  end

  # ============================================================================
  # INTENT CLASSIFICATION TESTS - Core Intents
  # ============================================================================

  test "classifies property_search intent" do
    queries = [ "find apartment", "search for house", "looking for 2 bedroom", "rent property" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :property_search, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies property_details intent" do
    queries = [ "what amenities", "tell me about this", "information about features" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :property_details, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies application_help intent" do
    queries = [ "how to apply", "documents needed for application", "application process" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :application_help, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies maintenance_help intent" do
    queries = [ "sink is broken", "not working", "need repair", "fix problem" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :maintenance_help, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies payment_help intent" do
    queries = [ "payment methods", "how to pay" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :payment_help, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies viewing_request intent" do
    queries = [ "schedule viewing", "tour", "visit", "schedule appointment" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :viewing_request, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies lease_questions intent" do
    queries = [ "lease terms", "agreement", "signing" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :lease_questions, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies account_help intent" do
    queries = [ "help with account", "update profile", "password reset", "login help" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :account_help, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies contact_info intent" do
    queries = [ "contact support", "email address", "phone number", "speak to someone" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :contact_info, response[:intent], "Failed for query: #{query}"
    end
  end

  test "classifies unknown intent" do
    queries = [ "xyzabc", "random nonsense", "gibberish" ]

    queries.each do |query|
      bot_service = BotService.new(user: @tenant, query: query, conversation: @conversation)
      response = bot_service.process_query

      assert_equal :unknown, response[:intent], "Failed for query: #{query}"
    end
  end

  # ============================================================================
  # HELPER METHOD TESTS
  # ============================================================================

  test "extract_number_before extracts number from query" do
    bot_service = BotService.new(user: @tenant, query: "find 3 bedroom apartment", conversation: @conversation)

    number = bot_service.send(:extract_number_before, [ "bedroom", "bed" ])
    assert_equal 3, number
  end

  test "extract_number_before returns nil when no number found" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)

    number = bot_service.send(:extract_number_before, [ "bedroom", "bed" ])
    assert_nil number
  end

  test "extract_price extracts price with dollar sign" do
    bot_service = BotService.new(user: @tenant, query: "properties under $2000", conversation: @conversation)

    price = bot_service.send(:extract_price)
    assert_equal 2000, price
  end

  test "extract_price extracts price with commas" do
    bot_service = BotService.new(user: @tenant, query: "budget $2,500", conversation: @conversation)

    price = bot_service.send(:extract_price)
    assert_equal 2500, price
  end

  test "extract_price returns nil when no price found" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)

    price = bot_service.send(:extract_price)
    assert_nil price
  end

  test "extract_property_type identifies apartment" do
    bot_service = BotService.new(user: @tenant, query: "looking for apartment", conversation: @conversation)

    type = bot_service.send(:extract_property_type)
    assert_equal "apartment", type
  end

  test "extract_property_type identifies house" do
    bot_service = BotService.new(user: @tenant, query: "find me a house", conversation: @conversation)

    type = bot_service.send(:extract_property_type)
    assert_equal "house", type
  end

  test "extract_property_type returns nil for no match" do
    bot_service = BotService.new(user: @tenant, query: "find property", conversation: @conversation)

    type = bot_service.send(:extract_property_type)
    assert_nil type
  end

  # ============================================================================
  # RESPONSE GENERATION TESTS
  # ============================================================================

  test "property_search response includes extracted criteria" do
    bot_service = BotService.new(user: @tenant, query: "find 2 bedroom apartment under $2000", conversation: @conversation)
    response = bot_service.process_query

    assert_equal :property_search, response[:intent]
    assert response[:response].include?("2 bedroom")
    assert response[:response].include?("$2000")
    assert response[:response].include?("apartment")
  end

  test "property_details response includes property info when conversation has property" do
    bot_service = BotService.new(user: @tenant, query: "tell me about this", conversation: @conversation)
    response = bot_service.process_query

    assert_equal :property_details, response[:intent]
    assert response[:response].include?(@property.title)
    assert response[:response].include?("$#{@property.price}")
  end

  test "property_details response when no specific property mentioned" do
    bot_service = BotService.new(user: @tenant, query: "amenities", conversation: nil)
    response = bot_service.process_query

    assert_equal :property_details, response[:intent]
    assert response[:response].present?
  end

  # ============================================================================
  # QUICK ACTIONS TESTS
  # ============================================================================

  test "returns property_search quick actions" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)
    response = bot_service.process_query

    assert_equal :property_search, response[:intent]
    assert_includes response[:quick_actions], "Search Properties"
  end

  test "returns application_help quick actions" do
    bot_service = BotService.new(user: @tenant, query: "how to apply", conversation: @conversation)
    response = bot_service.process_query

    assert_equal :application_help, response[:intent]
    assert_includes response[:quick_actions], "Start Application"
  end

  test "returns default quick actions for unknown intent" do
    bot_service = BotService.new(user: @tenant, query: "random query", conversation: @conversation)
    response = bot_service.process_query

    assert_equal :unknown, response[:intent]
    assert_includes response[:quick_actions], "Browse Properties"
  end

  # ============================================================================
  # CONFIDENCE SCORING TESTS
  # ============================================================================

  test "returns high confidence for known intents" do
    bot_service = BotService.new(user: @tenant, query: "find apartment", conversation: @conversation)
    response = bot_service.process_query

    assert_equal 0.8, response[:confidence]
  end

  test "returns low confidence for unknown intent" do
    bot_service = BotService.new(user: @tenant, query: "random nonsense", conversation: @conversation)
    response = bot_service.process_query

    assert_equal :unknown, response[:intent]
    assert_equal 0.3, response[:confidence]
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  test "handles nil query as blank query" do
    bot_service = BotService.new(user: @tenant, query: nil, conversation: @conversation)
    response = bot_service.process_query

    assert response.is_a?(Hash)
    assert_equal :greeting, response[:intent]
    assert response[:response].include?("Hello")
  end

  test "handles whitespace-only query as blank query" do
    bot_service = BotService.new(user: @tenant, query: "   ", conversation: @conversation)
    response = bot_service.process_query

    assert response.is_a?(Hash)
    assert_equal :greeting, response[:intent]
    assert response[:response].include?("Hello")
  end

  test "strips and lowercases query on initialization" do
    bot_service = BotService.new(user: @tenant, query: "  FIND APARTMENT  ", conversation: @conversation)

    assert_equal "find apartment", bot_service.instance_variable_get(:@query)
  end
end
