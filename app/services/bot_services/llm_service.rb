# frozen_string_literal: true

module BotServices
  # LLM-powered response generation service for Ofie Assistant
  # Provides intelligent, context-aware responses using configured LLM providers
  # with graceful fallback to rule-based responses
  class LlmService
    attr_reader :user, :query, :conversation, :context, :streaming

    # LLM Configuration
    MAX_PROMPT_TOKENS = 3000
    MAX_RESPONSE_TOKENS = 500
    MAX_CONVERSATION_HISTORY = 10
    CACHE_EXPIRES_IN = 1.hour
    REQUEST_TIMEOUT = 10.seconds

    # Provider fallback order
    PROVIDER_ORDER = [ :anthropic, :openai, :google ].freeze

    def initialize(user:, query:, conversation: nil, context: {}, streaming: false)
      @user = user
      @query = query
      @conversation = conversation
      @context = context
      @streaming = streaming
    end

    # Generate response using LLM with fallback
    def generate_response
      cached_response = check_cache
      return cached_response if cached_response

      begin
        response_text = call_llm

        if valid_response?(response_text)
          result = {
            success: true,
            response: response_text,
            source: :llm,
            cached: false
          }
          cache_response(result)
          result
        else
          Rails.logger.warn "[BotLlmService] Invalid LLM response, falling back to rules"
          fallback_response
        end
      rescue => e
        Rails.logger.warn "[BotLlmService] LLM error: #{e.message}. Falling back to rule-based response."
        fallback_response
      end
    end

    # Generate streaming response
    def generate_streaming_response(&block)
      return unless streaming && block_given?

      begin
        stream_llm(&block)
      rescue => e
        Rails.logger.warn "[BotLlmService] Streaming error: #{e.message}. Falling back."
        response = generate_response
        yield response[:response] if response[:success]
      end
    end

    private

    # Call configured LLM providers in fallback order
    def call_llm
      PROVIDER_ORDER.each do |provider|
        result = try_provider(provider)
        return result if result.present?
      end

      raise StandardError, "All LLM providers failed"
    end

    # Try specific LLM provider
    def try_provider(provider)
      return nil unless provider_configured?(provider)

      case provider
      when :anthropic
        call_anthropic
      when :openai
        call_openai
      when :google
        call_google
      end
    rescue => e
      Rails.logger.debug "[BotLlmService] Provider #{provider} failed: #{e.message}"
      nil
    end

    # Anthropic Claude integration
    def call_anthropic
      return nil unless defined?(LLM)

      client = LLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])

      response = client.chat(
        model: "claude-3-5-sonnet-20241022",
        messages: [
          { role: "user", content: build_prompt }
        ],
        system: system_prompt,
        max_tokens: MAX_RESPONSE_TOKENS,
        temperature: 0.7
      )

      response.dig("content", 0, "text")
    end

    # OpenAI GPT integration
    def call_openai
      return nil unless defined?(LLM)

      client = LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

      response = client.chat(
        model: "gpt-4-turbo-preview",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: build_prompt }
        ],
        max_tokens: MAX_RESPONSE_TOKENS,
        temperature: 0.7
      )

      response.dig("choices", 0, "message", "content")
    end

    # Google Gemini integration
    def call_google
      return nil unless defined?(LLM)

      client = LLM::Google.new(api_key: ENV["GOOGLE_API_KEY"])

      response = client.generate_content(
        model: "gemini-pro",
        contents: [
          { role: "user", parts: [ { text: "#{system_prompt}\n\n#{build_prompt}" } ] }
        ],
        generation_config: {
          max_output_tokens: MAX_RESPONSE_TOKENS,
          temperature: 0.7
        }
      )

      response.dig("candidates", 0, "content", "parts", 0, "text")
    end

    # Stream LLM response
    def stream_llm(&block)
      return unless defined?(LLM) && provider_configured?(:anthropic)

      client = LLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])

      client.chat_stream(
        model: "claude-3-5-sonnet-20241022",
        messages: [ { role: "user", content: build_prompt } ],
        system: system_prompt,
        max_tokens: MAX_RESPONSE_TOKENS
      ) do |chunk|
        text = chunk.dig("delta", "text")
        yield text if text.present?
      end
    end

    # Build comprehensive prompt with context
    def build_prompt
      prompt_parts = []

      # Add conversation history
      if conversation&.messages&.any?
        prompt_parts << "Previous conversation:\n"
        prompt_parts << format_conversation_history
        prompt_parts << "\n"
      end

      # Add property context
      if conversation&.property
        prompt_parts << format_property_context
        prompt_parts << "\n"
      end

      # Add user preferences
      if context[:user_preferences].present?
        prompt_parts << format_user_preferences
        prompt_parts << "\n"
      end

      # Add current query
      prompt_parts << "User's current question: #{query}"

      prompt_parts.join("\n")
    end

    # System prompt for rental assistant
    def system_prompt
      <<~PROMPT
        You are Ofie Assistant, a helpful and knowledgeable AI assistant for a rental property platform.

        Your role is to:
        - Help users find rental properties that match their needs
        - Explain the rental application process clearly
        - Provide information about properties, neighborhoods, and amenities
        - Guide users through scheduling viewings and submitting applications
        - Answer questions about payments, maintenance requests, and lease terms
        - Be friendly, professional, and concise in your responses

        Guidelines:
        - Keep responses under 300 words
        - Be specific and actionable
        - If you don't know something, say so and suggest how the user can find out
        - Always prioritize user safety and legal compliance
        - Never make promises on behalf of landlords
        - Respect user privacy and data

        User context:
        - User name: #{user.name}
        - User role: #{user.role}
        - Platform: Ofie Rental Platform
      PROMPT
    end

    # Format conversation history for context
    def format_conversation_history
      return "" unless conversation&.messages

      conversation.messages
        .order(created_at: :desc)
        .limit(MAX_CONVERSATION_HISTORY)
        .reverse
        .map { |msg| "#{msg.sender.name}: #{msg.content}" }
        .join("\n")
    end

    # Format property context
    def format_property_context
      property = conversation.property
      <<~CONTEXT
        Current property being discussed:
        - Title: #{property.title}
        - Location: #{property.address}, #{property.city}
        - Price: $#{property.price}/month
        - Bedrooms: #{property.bedrooms}, Bathrooms: #{property.bathrooms}
        - Type: #{property.property_type}
        - Description: #{property.description&.truncate(200)}
      CONTEXT
    end

    # Format user preferences
    def format_user_preferences
      prefs = context[:user_preferences]
      parts = [ "User's preferences:" ]

      parts << "- Budget: up to $#{prefs[:budget_max]}" if prefs[:budget_max]
      parts << "- Preferred amenities: #{prefs[:preferred_amenities].join(', ')}" if prefs[:preferred_amenities]&.any?

      parts.join("\n")
    end

    # Fallback to rule-based response
    def fallback_response
      fallback_service = BotService.new(
        user: user,
        query: query,
        conversation: conversation,
        context: context,
        use_llm: false  # Explicitly disable LLM to prevent infinite loop
      )

      bot_response = fallback_service.process_query

      {
        success: true,
        response: bot_response[:response] || bot_response,
        source: :fallback,
        cached: false
      }
    end

    # Validate LLM response quality
    def valid_response?(response)
      return false if response.blank?
      return false if response.length < 10
      return false if response.length > 2000

      # Check for common LLM placeholder phrases
      invalid_phrases = [
        "as an ai",
        "i don't have access",
        "i cannot",
        "i apologize, but i"
      ]

      return false if invalid_phrases.any? { |phrase| response.downcase.include?(phrase) }

      true
    end

    # Cache management
    def cache_key
      Digest::SHA256.hexdigest("bot_llm:#{user.id}:#{query}:#{conversation&.id}")
    end

    def check_cache
      cached = Rails.cache.read(cache_key)
      return nil unless cached

      cached.merge(cached: true)
    end

    def cache_response(response)
      Rails.cache.write(cache_key, response, expires_in: CACHE_EXPIRES_IN)
    end

    # Check if provider is configured
    def provider_configured?(provider)
      case provider
      when :anthropic
        ENV["ANTHROPIC_API_KEY"].present?
      when :openai
        ENV["OPENAI_API_KEY"].present?
      when :google
        ENV["GOOGLE_API_KEY"].present?
      else
        false
      end
    end

    # Provider order for fallback
    def provider_order
      PROVIDER_ORDER
    end
  end
end
