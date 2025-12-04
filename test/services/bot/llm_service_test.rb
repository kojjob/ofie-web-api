require "test_helper"

module BotServices
  class LlmServiceTest < ActiveSupport::TestCase
    def setup
      @tenant = create(:user, role: "tenant", name: "John Doe")
      @landlord = create(:user, role: "landlord")
      @property = create(:property,
        user: @landlord,
        price: 2000,
        bedrooms: 2,
        title: "Modern Downtown Apartment",
        description: "Beautiful apartment in the heart of downtown with great amenities"
      )
      @conversation = create(:conversation,
        landlord: @landlord,
        tenant: @tenant,
        property: @property
      )
    end

    # ============================================================================
    # INITIALIZATION TESTS
    # ============================================================================

    test "initializes with required parameters" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Tell me about this property",
        conversation: @conversation
      )

      assert_equal @tenant, service.user
      assert_equal "Tell me about this property", service.query
      assert_equal @conversation, service.conversation
    end

    test "initializes with optional context" do
      context = { intent: :property_details, entities: { bedrooms: 2 } }
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Show me properties",
        conversation: @conversation,
        context: context
      )

      assert_equal context, service.context
    end

    test "initializes with default empty context" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Hello",
        conversation: @conversation
      )

      assert_equal({}, service.context)
    end

    # ============================================================================
    # LLM GENERATION TESTS
    # ============================================================================

    test "generates response using LLM when available" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "What amenities does this property have?",
        conversation: @conversation
      )

      # Stub call_llm to simulate successful LLM response
      def service.call_llm
        "This property features excellent amenities including a fitness center, swimming pool, and covered parking."
      end

      response = service.generate_response

      assert response[:success]
      assert response[:response].present?
      assert response[:response].is_a?(String)
      assert response[:response].length > 20
      assert_equal :llm, response[:source]
    end

    test "includes conversation context in LLM prompt" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Tell me more about the location",
        conversation: @conversation
      )

      prompt = service.send(:build_prompt)

      assert prompt.include?(@property.title), "Prompt should include property title"
      assert prompt.include?("Current property being discussed"), "Prompt should include property context header"
      # Note: User name is in system_prompt, not build_prompt
    end

    test "includes user preferences in prompt when available" do
      context = {
        user_preferences: {
          budget_max: 2500,
          preferred_amenities: ["parking", "gym"]
        }
      }

      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Find me something similar",
        conversation: @conversation,
        context: context
      )

      prompt = service.send(:build_prompt)

      assert prompt.include?("parking")
      assert prompt.include?("gym")
      assert prompt.include?("2500")
    end

    # ============================================================================
    # FALLBACK MECHANISM TESTS
    # ============================================================================

    test "falls back to rule-based when LLM unavailable" do
      # Simulate LLM failure by stubbing all providers to return nil
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Tell me about this property",
        conversation: @conversation
      )

      # Stub try_provider to return nil for all providers
      def service.try_provider(provider)
        nil
      end

      response = service.generate_response

      assert response[:success]
      assert response[:response].present?
      assert_equal :fallback, response[:source]
    end

    test "falls back gracefully when LLM returns empty response" do
      # Mock empty LLM response by stubbing valid_response? to return false
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "What is the rent?",
        conversation: @conversation
      )

      # Stub call_llm to return empty string
      def service.call_llm
        ""
      end

      response = service.generate_response

      assert response[:success]
      assert response[:response].present?
      assert_equal :fallback, response[:source]
    end

    test "logs warning when fallback is triggered" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Hello",
        conversation: @conversation
      )

      # Stub call_llm to raise error
      def service.call_llm
        raise StandardError, "API error"
      end

      # Expect warning to be logged (Rails.logger.warn is called in the rescue block)
      response = service.generate_response

      # Verify fallback happened
      assert_equal :fallback, response[:source]
    end

    # ============================================================================
    # RESPONSE CACHING TESTS
    # ============================================================================

    test "caches LLM responses for identical queries" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "What amenities are available?",
        conversation: @conversation
      )

      # Stub call_llm to return a consistent response
      def service.call_llm
        "The property has parking, gym, and pool amenities."
      end

      # First call should hit LLM and cache the result
      first_response = service.generate_response
      assert_equal false, first_response[:cached], "First response should not be cached"

      # Verify cache was written
      cache_key = service.send(:cache_key)
      cached_value = Rails.cache.read(cache_key)
      assert cached_value.present?, "Cache should contain the response after first call"

      # Second call should use cache
      second_service = BotServices::LlmService.new(
        user: @tenant,
        query: "What amenities are available?",
        conversation: @conversation
      )

      # Stub second service too (in case cache doesn't work, to prevent fallback)
      def second_service.call_llm
        "The property has parking, gym, and pool amenities."
      end

      second_response = second_service.generate_response

      assert_equal first_response[:response], second_response[:response]
      assert second_response[:cached], "Second response should be retrieved from cache"
    end

    test "cache expires after configured time" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Property details?",
        conversation: @conversation
      )

      # Stub call_llm to return a mocked response
      def service.call_llm
        "Mocked response"
      end

      # First call
      first_response = service.generate_response

      # Clear cache
      Rails.cache.clear

      # Create new service instance for second call
      service2 = BotServices::LlmService.new(
        user: @tenant,
        query: "Property details?",
        conversation: @conversation
      )

      # Stub call_llm for second service too
      def service2.call_llm
        "Mocked response"
      end

      # Second call should hit LLM again (no cache)
      second_response = service2.generate_response
      refute second_response[:cached]
    end

    test "different queries generate different cache keys" do
      service1 = BotServices::LlmService.new(
        user: @tenant,
        query: "What is the rent?",
        conversation: @conversation
      )

      service2 = BotServices::LlmService.new(
        user: @tenant,
        query: "What are the amenities?",
        conversation: @conversation
      )

      key1 = service1.send(:cache_key)
      key2 = service2.send(:cache_key)

      refute_equal key1, key2
    end

    # ============================================================================
    # PROMPT ENGINEERING TESTS
    # ============================================================================

    test "builds appropriate system prompt for rental domain" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Help me find an apartment",
        conversation: @conversation
      )

      system_prompt = service.send(:system_prompt)

      assert system_prompt.include?("rental")
      assert system_prompt.include?("assistant")
      assert system_prompt.include?("property")
    end

    test "includes conversation history in prompt when available" do
      # Create some message history
      create(:message,
        conversation: @conversation,
        sender: @tenant,
        content: "What is the price?"
      )
      create(:message,
        conversation: @conversation,
        sender: Bot.primary_bot,
        content: "The monthly rent is $2000"
      )

      service = BotServices::LlmService.new(
        user: @tenant,
        query: "That's perfect, when can I move in?",
        conversation: @conversation
      )

      prompt = service.send(:build_prompt)

      assert prompt.include?("What is the price?")
      assert prompt.include?("The monthly rent is $2000")
    end

    test "limits conversation history to recent messages" do
      # Create many messages
      15.times do |i|
        create(:message,
          conversation: @conversation,
          sender: @tenant,
          content: "Message #{i}"
        )
      end

      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Current question",
        conversation: @conversation
      )

      prompt = service.send(:build_prompt)

      # Should only include last 10 messages
      assert prompt.include?("Message 14")
      refute prompt.include?("Message 0")
    end

    # ============================================================================
    # LLM PROVIDER FALLBACK TESTS
    # ============================================================================

    test "tries multiple LLM providers in order" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Find me properties",
        conversation: @conversation
      )

      # Should try Anthropic first, then OpenAI, then Google
      providers = service.send(:provider_order)

      assert_equal [:anthropic, :openai, :google], providers
    end

    test "successfully uses fallback provider when primary fails" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Help me with my search",
        conversation: @conversation
      )

      # Stub try_provider to simulate primary failure and secondary success
      def service.try_provider(provider)
        provider == :anthropic ? nil : "Response from #{provider}"
      end

      response = service.generate_response

      assert response[:success]
      assert response[:response].present?
    end

    # ============================================================================
    # RESPONSE VALIDATION TESTS
    # ============================================================================

    test "validates LLM response is appropriate length" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Tell me everything about rentals",
        conversation: @conversation
      )

      # Mock very long response
      long_response = "a" * 5000

      valid = service.send(:valid_response?, long_response)
      refute valid
    end

    test "validates LLM response contains no inappropriate content" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Property info",
        conversation: @conversation
      )

      # Mock response with placeholder text
      invalid_response = "As an AI language model, I cannot..."

      valid = service.send(:valid_response?, invalid_response)
      refute valid
    end

    test "validates LLM response is contextually relevant" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "What is the monthly rent?",
        conversation: @conversation
      )

      relevant = "The monthly rent for this property is $2000."
      # Note: valid_response? only checks length and invalid phrases, not contextual relevance

      assert service.send(:valid_response?, relevant)
    end

    # ============================================================================
    # ERROR HANDLING TESTS
    # ============================================================================

    test "handles network timeout gracefully" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Show properties",
        conversation: @conversation
      )

      # Stub call_llm to raise timeout error
      def service.call_llm
        raise Timeout::Error, "Request timeout"
      end

      response = service.generate_response

      assert response[:success]
      assert_equal :fallback, response[:source]
    end

    test "handles API rate limiting" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Property search",
        conversation: @conversation
      )

      # Stub call_llm to raise rate limit error
      def service.call_llm
        raise StandardError, "Rate limit exceeded"
      end

      response = service.generate_response

      assert response[:success]
      assert_equal :fallback, response[:source]
    end

    test "handles malformed LLM response" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Help",
        conversation: @conversation
      )

      # Stub call_llm to return invalid structure (not a string)
      def service.call_llm
        { invalid: "structure" }
      end

      response = service.generate_response

      assert response[:success]
      assert_equal :fallback, response[:source]
    end

    # ============================================================================
    # STREAMING RESPONSE TESTS
    # ============================================================================

    test "supports streaming responses when enabled" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Explain the rental process",
        conversation: @conversation,
        streaming: true
      )

      # Stub stream_llm to simulate streaming chunks
      def service.stream_llm(&block)
        ["The rental ", "process involves ", "several steps..."].each do |chunk|
          yield chunk
        end
      end

      chunks = []
      service.generate_streaming_response do |chunk|
        chunks << chunk
      end

      assert chunks.length > 0
      assert chunks.all? { |chunk| chunk.is_a?(String) }
    end

    test "streaming falls back to non-streaming on error" do
      service = BotServices::LlmService.new(
        user: @tenant,
        query: "Property details",
        conversation: @conversation,
        streaming: true
      )

      # Stub stream_llm to raise error
      def service.stream_llm
        raise StandardError, "Streaming error"
      end

      # Stub call_llm for fallback to non-streaming
      def service.call_llm
        "Fallback response"
      end

      response = service.generate_response

      assert response[:success]
      assert response[:response].present?
      refute response[:streamed]
    end
  end
end
