# 🤖 Ofie Intelligent Rental Assistant Bot

A comprehensive AI-powered chatbot system for rental property platforms with advanced natural language processing, contextual awareness, and beautiful user interface.

## ✨ Features

### 🧠 Advanced AI Capabilities
- **Natural Language Processing** - Advanced intent classification and entity extraction
- **Context Awareness** - Maintains conversation state and user preferences
- **Personality Engine** - Adaptive communication style based on user behavior
- **Confidence Scoring** - AI confidence assessment for response quality
- **Smart Actions** - Contextual quick actions and suggestions

### 🏠 Domain Expertise
- **Property Search** - Intelligent property recommendations with ML-based scoring
- **Application Guidance** - Step-by-step rental application assistance
- **Lease Consultation** - Legal guidance and lease term explanations
- **Maintenance Support** - Emergency protocols and maintenance request handling
- **Financial Planning** - Budget analysis and rental cost calculations
- **Neighborhood Insights** - Local area information and market trends

### 💬 Real-time Communication
- **WebSocket Integration** - Real-time messaging with ActionCable
- **Typing Indicators** - Live typing status and presence detection
- **Message Status** - Read receipts and delivery confirmations
- **Rich Media Support** - Images, property cards, and interactive elements

### 🎨 Beautiful User Interface
- **Floating Widget** - Elegant bottom-right chat interface
- **Smooth Animations** - Framer Motion powered interactions
- **Responsive Design** - Mobile-first adaptive layout
- **Dark Mode Support** - Automatic theme detection
- **Accessibility** - WCAG compliant with keyboard navigation

### 📊 Analytics & Learning
- **User Behavior Tracking** - Interaction analytics and engagement metrics
- **Bot Performance Monitoring** - Intent accuracy and response quality
- **Feedback System** - User satisfaction tracking and improvement insights
- **A/B Testing Support** - Response variation testing capabilities

## 🚀 Quick Start

### Installation

1. **Add to your Rails application:**

```bash
# Add to Gemfile
gem 'redis', '~> 4.0'
gem 'jwt'

# Install dependencies
bundle install
```

2. **Run migrations:**

```bash
rails db:migrate
```

3. **Add bot styles to your application:**

```scss
// app/assets/stylesheets/application.scss
@import "bot";
```

4. **Include JavaScript components:**

```javascript
// app/javascript/application.js
import BotIntegration from './components/bot/BotIntegration'
```

### Basic Usage

1. **Initialize the bot on any page:**

```html
<!-- In your layout or specific pages -->
<div id="ofie-bot-root"></div>

<script>
  // Initialize when page loads
  document.addEventListener('DOMContentLoaded', function() {
    window.initializeOfieBot({
      user: {
        id: 1,
        name: "John Doe",
        email: "john@example.com",
        role: "tenant"
      },
      apiBaseUrl: '/api/v1',
      theme: 'default',
      enabled: true
    });
  });
</script>
```

2. **Start a conversation:**

```javascript
// Send a message to the bot
fetch('/api/v1/bot/send_message', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${authToken}`
  },
  body: JSON.stringify({
    message: "I'm looking for a 2-bedroom apartment",
    property_id: null // or specific property ID
  })
});
```

## 📡 API Reference

### Bot Endpoints

#### Send Message
```http
POST /api/v1/bot/send_message
```

**Request:**
```json
{
  "message": "Find me properties in Seattle",
  "property_id": 123,
  "context": {
    "page": "property_listing",
    "user_action": "inquiry"
  }
}
```

**Response:**
```json
{
  "conversation_id": 456,
  "user_message": {
    "id": 789,
    "content": "Find me properties in Seattle",
    "created_at": "2024-01-01T12:00:00Z"
  },
  "bot_response": {
    "message": {
      "id": 790,
      "content": "I'd be happy to help you find properties in Seattle!",
      "metadata": {
        "intent": "property_search_advanced",
        "confidence": 0.92,
        "entities": {
          "location": "Seattle"
        }
      }
    },
    "smart_actions": [
      {
        "type": "quick_search",
        "label": "Search Properties",
        "icon": "🔍"
      }
    ],
    "conversation_suggestions": [
      "Show me 2-bedroom apartments",
      "What's the average rent in Seattle?",
      "Find pet-friendly properties"
    ]
  }
}
```

#### Get Conversation Starters
```http
GET /api/v1/bot/conversation_starters
```

**Response:**
```json
{
  "greeting": "Hi John! I'm here to help you find the perfect rental.",
  "conversation_starters": [
    "Find me properties in my area",
    "Help me understand the application process",
    "What documents do I need?",
    "Calculate my rental budget"
  ]
}
```

#### Submit Feedback
```http
POST /api/v1/bot/feedback
```

**Request:**
```json
{
  "message_id": 790,
  "feedback_type": "helpful",
  "details": "Great property recommendations!"
}
```

### Property Search with AI
```http
POST /api/v1/properties/search_with_ai
```

**Request:**
```json
{
  "query": "2 bedroom apartment near downtown with parking",
  "user_preferences": {
    "budget_max": 2500,
    "preferred_amenities": ["parking", "pets"]
  },
  "context": {
    "conversation_id": 456
  }
}
```

## 🛠️ Configuration

### Environment Variables

```env
# Redis for ActionCable and caching
REDIS_URL=redis://localhost:6379/0

# JWT Secret
SECRET_KEY_BASE=your_secret_key

# Bot Configuration
BOT_CONFIDENCE_THRESHOLD=0.7
BOT_RESPONSE_DELAY_MS=1500
BOT_MAX_SUGGESTIONS=3

# Analytics
ANALYTICS_ENABLED=true
FEEDBACK_COLLECTION_ENABLED=true
```

### Customization

#### Personality Configuration

```ruby
# config/initializers/bot_config.rb
Bot::PersonalityEngine.configure do |config|
  config.enthusiasm_level = 0.8
  config.formality_level = :friendly
  config.emoji_usage = :moderate
  config.response_length = :balanced
end
```

#### Custom Intent Patterns

```ruby
# Add custom intents to the NLP processor
Bot::NaturalLanguageProcessor::INTENT_PATTERNS.merge!({
  custom_intent: {
    primary: [/your|custom|pattern/i],
    confidence_base: 0.8
  }
})
```

#### Custom Response Templates

```ruby
# app/services/bot/custom_response_templates.rb
class Bot::CustomResponseTemplates < Bot::ResponseTemplates
  def self.handle_custom_intent(entities, context)
    "Your custom response logic here"
  end
end
```

## 🎨 Theming

### CSS Custom Properties

```css
:root {
  --bot-primary-color: #3b82f6;
  --bot-secondary-color: #8b5cf6;
  --bot-success-color: #10b981;
  --bot-border-radius: 16px;
  --bot-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
}
```

### Theme Variants

```javascript
// Light theme (default)
initializeOfieBot({ theme: 'light' });

// Dark theme
initializeOfieBot({ theme: 'dark' });

// Auto theme (follows system preference)
initializeOfieBot({ theme: 'auto' });

// Custom theme
initializeOfieBot({ 
  theme: 'custom',
  themeConfig: {
    primaryColor: '#your-color',
    borderRadius: '12px'
  }
});
```

## 📊 Analytics Dashboard

### Bot Performance Metrics

```javascript
// Get bot analytics
fetch('/api/v1/bot/analytics')
  .then(response => response.json())
  .then(data => {
    console.log('Intent accuracy:', data.intent_accuracy);
    console.log('User satisfaction:', data.user_satisfaction);
    console.log('Response times:', data.response_times);
  });
```

### Custom Analytics Events

```javascript
// Track custom events
BotAnalytics.track('property_inquiry', {
  property_id: 123,
  user_id: 456,
  intent: 'property_details',
  confidence: 0.92
});
```

## 🧪 Testing

### Running Tests

```bash
# Run bot-specific tests
rails test test/services/bot/
rails test test/controllers/api/v1/bot_controller_test.rb

# Run integration tests
rails test test/integration/bot_conversation_test.rb
```

### Test Helpers

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  def create_bot_conversation(user, property: nil)
    Bot::ConversationManagerService.new(user)
                                   .find_or_create_conversation(property: property)
  end
  
  def simulate_bot_response(conversation, message)
    Bot::IntelligentBotEngine.new(
      user: conversation.tenant,
      conversation: conversation
    ).process_message(message)
  end
end
```

### Example Tests

```ruby
# test/services/bot/intelligent_bot_engine_test.rb
class Bot::IntelligentBotEngineTest < ActiveSupport::TestCase
  def setup
    @user = users(:tenant_user)
    @conversation = create_bot_conversation(@user)
    @bot_engine = Bot::IntelligentBotEngine.new(
      user: @user, 
      conversation: @conversation
    )
  end
  
  test "classifies property search intent correctly" do
    response = @bot_engine.process_message("I need a 2 bedroom apartment")
    
    assert_equal :property_search_advanced, response[:intent]
    assert response[:confidence] > 0.8
    assert_equal 2, response[:entities][:bedroom_count]
  end
  
  test "generates smart actions for property search" do
    response = @bot_engine.process_message("Find me apartments in Seattle")
    
    assert_includes response[:smart_actions].map { |a| a[:type] }, 'quick_search'
    assert_includes response[:smart_actions].map { |a| a[:type] }, 'save_search'
  end
end
```

## 🔧 Advanced Features

### Custom NLP Pipeline

```ruby
# app/services/bot/custom_nlp_processor.rb
class Bot::CustomNlpProcessor < Bot::NaturalLanguageProcessor
  def classify_intent_advanced(message, context = {})
    # Add your custom NLP logic
    # Integrate with external NLP services (OpenAI, Google NLP, etc.)
    
    super(message, context)
  end
  
  def extract_entities(message)
    entities = super(message)
    
    # Add custom entity extraction
    entities[:custom_entity] = extract_custom_entity(message)
    
    entities
  end
end
```

### Integration with External APIs

```ruby
# app/services/bot/external_integrations.rb
class Bot::ExternalIntegrations
  def self.get_property_details(property_id)
    # Integrate with external property APIs
    # MLS, Rentals.com, etc.
  end
  
  def self.get_neighborhood_data(location)
    # Integrate with location APIs
    # Walk Score, Crime Data, School Ratings
  end
  
  def self.verify_income(application_data)
    # Integrate with income verification services
  end
end
```

### Webhook Support

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :webhooks do
      post :bot_feedback
      post :property_updated
      post :application_status_changed
    end
  end
end

# app/controllers/api/v1/webhooks/bot_controller.rb
class Api::V1::Webhooks::BotController < ApplicationController
  def feedback
    # Handle external feedback webhooks
    Bot::FeedbackProcessor.process(params[:feedback_data])
    head :ok
  end
end
```

## 📱 Mobile Integration

### React Native Component

```javascript
// BotWidget.js
import React from 'react';
import { View, TouchableOpacity, Text } from 'react-native';
import { WebView } from 'react-native-webview';

export const BotWidget = ({ user, apiBaseUrl }) => {
  const [isOpen, setIsOpen] = useState(false);
  
  return (
    <View style={styles.container}>
      {isOpen && (
        <WebView
          source={{ uri: `${apiBaseUrl}/bot/mobile` }}
          style={styles.webview}
        />
      )}
      <TouchableOpacity 
        style={styles.button}
        onPress={() => setIsOpen(!isOpen)}
      >
        <Text>🤖</Text>
      </TouchableOpacity>
    </View>
  );
};
```

## 🌍 Internationalization

### Multi-language Support

```ruby
# config/locales/bot.en.yml
en:
  bot:
    greetings:
      morning: "Good morning! How can I help you today?"
      afternoon: "Good afternoon! What can I assist you with?"
    intents:
      property_search: "I'll help you find the perfect property!"
      
# config/locales/bot.es.yml
es:
  bot:
    greetings:
      morning: "¡Buenos días! ¿Cómo puedo ayudarte hoy?"
      afternoon: "¡Buenas tardes! ¿En qué puedo asistirte?"
```

```ruby
# app/services/bot/i18n_response_generator.rb
class Bot::I18nResponseGenerator
  def self.generate_response(intent, locale = :en)
    I18n.with_locale(locale) do
      I18n.t("bot.intents.#{intent}")
    end
  end
end
```

## 🔒 Security & Privacy

### Data Protection

```ruby
# app/models/bot/learning_data.rb
class Bot::LearningData < ApplicationRecord
  # Encrypt sensitive fields
  encrypts :message, :entities, :context
  
  # Auto-delete old data
  scope :expired, -> { where('created_at < ?', 6.months.ago) }
  
  def self.cleanup_expired_data
    expired.delete_all
  end
end
```

### Rate Limiting

```ruby
# config/application.rb
config.middleware.use Rack::Attack

# config/initializers/rack_attack.rb
Rack::Attack.throttle('bot_messages', limit: 30, period: 1.minute) do |req|
  req.ip if req.path.match?(/\/api\/v1\/bot\//)
end
```

## 📈 Performance Optimization

### Caching Strategy

```ruby
# app/services/bot/response_cache.rb
class Bot::ResponseCache
  def self.get_cached_response(message_hash)
    Rails.cache.read("bot_response:#{message_hash}")
  end
  
  def self.cache_response(message_hash, response)
    Rails.cache.write("bot_response:#{message_hash}", response, expires_in: 1.hour)
  end
end
```

### Background Jobs

```ruby
# app/jobs/bot/analytics_job.rb
class Bot::AnalyticsJob < ApplicationJob
  queue_as :bot_analytics
  
  def perform(interaction_data)
    Bot::AnalyticsService.process_interaction(interaction_data)
  end
end
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Development Setup

```bash
# Clone and setup
git clone https://github.com/your-org/ofie-bot.git
cd ofie-bot
bundle install
rails db:setup

# Run tests
rails test

# Start development server
rails server
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Ruby on Rails 7
- UI powered by Tailwind CSS and Framer Motion
- Real-time communication via ActionCable
- NLP processing with custom algorithms
- Inspired by modern conversational AI systems

## 🆘 Support

- 📧 Email: support@ofie.com
- 📖 Documentation: [docs.ofie.com/bot](https://docs.ofie.com/bot)
- 💬 Discord: [Ofie Community](https://discord.gg/ofie)
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/ofie-bot/issues)

---

**Made with ❤️ by the Ofie Team**