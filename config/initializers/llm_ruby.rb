# frozen_string_literal: true

# LLM Ruby Configuration
# This initializer sets up the llm_ruby gem for AI lease generation
# It configures multiple LLM providers with automatic fallback

# Configure LLM providers with credentials from Rails credentials or environment variables
LlmRuby.configure do |config|
  # OpenAI Configuration (GPT-4, GPT-3.5-turbo)
  config.openai_api_key = Rails.application.credentials.dig(:llm, :openai, :api_key) || ENV["OPENAI_API_KEY"]

  # Anthropic Configuration (Claude 3 Opus, Sonnet, Haiku)
  config.anthropic_api_key = Rails.application.credentials.dig(:llm, :anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]

  # Google Configuration (Gemini Pro, Gemini Pro Vision)
  config.google_api_key = Rails.application.credentials.dig(:llm, :google, :api_key) || ENV["GOOGLE_API_KEY"]

  # Global Configuration
  config.default_provider = :anthropic # Primary provider for lease generation
  config.timeout = 30 # Request timeout in seconds
  config.max_retries = 2 # Number of retries on failure
  config.log_requests = Rails.env.development? || Rails.env.test? # Log API requests in dev/test
end

# Validate that at least one provider is configured
Rails.application.config.after_initialize do
  providers_configured = {
    openai: LlmRuby.configuration.openai_api_key.present?,
    anthropic: LlmRuby.configuration.anthropic_api_key.present?,
    google: LlmRuby.configuration.google_api_key.present?
  }

  configured_count = providers_configured.values.count(true)

  if configured_count == 0
    Rails.logger.warn "[LLM Configuration] No LLM providers configured. AI lease generation will fall back to templates."
    Rails.logger.warn "[LLM Configuration] Set OPENAI_API_KEY, ANTHROPIC_API_KEY, or GOOGLE_API_KEY environment variables."
  else
    Rails.logger.info "[LLM Configuration] #{configured_count} LLM provider(s) configured: #{providers_configured.select { |k, v| v }.keys.join(', ')}"
  end
end

# Log configuration status
if Rails.env.development?
  Rails.logger.info "[LLM Configuration] LLM Ruby initialized successfully"
  Rails.logger.info "[LLM Configuration] Default provider: #{LlmRuby.configuration.default_provider}"
  Rails.logger.info "[LLM Configuration] Request timeout: #{LlmRuby.configuration.timeout}s"
  Rails.logger.info "[LLM Configuration] Max retries: #{LlmRuby.configuration.max_retries}"
end
