# Ofie Assistant Bot Documentation

This document provides comprehensive information about the AI-powered bot functionality integrated into the Ofie rental platform.

## Overview

The Ofie Assistant is an intelligent bot designed to help both tenants and landlords navigate the rental platform efficiently. It provides contextual assistance, answers common questions, and guides users through various processes.

## Features

### Core Capabilities
- **Natural Language Processing**: Understands user queries and provides relevant responses
- **Role-based Assistance**: Tailored responses for tenants, landlords, and general users
- **Contextual Awareness**: Considers conversation history and property context
- **Intent Recognition**: Classifies user queries into specific categories
- **Quick Actions**: Provides actionable suggestions based on user needs
- **Knowledge Base Integration**: Access to comprehensive platform information

### Supported Intents
- **Greeting**: Welcome messages and general hellos
- **Property Search**: Finding and filtering properties
- **Rental Applications**: Application process guidance
- **Maintenance Requests**: Reporting and tracking maintenance issues
- **Payments**: Rent payment processes and troubleshooting
- **Platform Help**: General platform navigation and features
- **Contact Support**: Escalation to human support when needed

## Architecture

### Models
- **Bot** (`app/models/bot.rb`): Extends User model with bot-specific functionality
- **User**: Base model that bots inherit from
- **Conversation**: Manages conversations between users and bots
- **Message**: Individual messages within conversations

### Services
- **BotService** (`app/services/bot_service.rb`): Core NLP and response generation
- **KnowledgeBase** (`app/services/knowledge_base.rb`): Static knowledge repository
- **MessagingService**: Handles conversation and message creation

### Controllers
- **Api::BotController** (`app/controllers/api/bot_controller.rb`): API endpoints for bot interactions
- **ConversationsController**: Enhanced with bot integration
- **MessagesController**: Automatic bot response triggers

## API Endpoints

### POST /api/v1/bot/chat
Send a message to the bot and receive a response.

**Request:**
```json
{
  "query": "How do I apply for a rental?",
  "conversation_id": "optional-existing-conversation-id"
}
```

**Response:**
```json
{
  "conversation_id": "uuid",
  "message": {
    "id": "uuid",
    "content": "To apply for a rental, you'll need...",
    "sender": {
      "id": "uuid",
      "name": "Ofie Assistant",
      "role": "bot"
    },
    "created_at": "2024-12-20T10:00:00Z"
  },
  "intent": "rental_application",
  "quick_actions": ["Start Application", "View Requirements"],
  "confidence": 0.95
}
```

### POST /api/v1/bot/start_conversation
Initiate a new conversation with the bot.

**Request:**
```json
{
  "property_id": "optional-property-uuid",
  "message": "I'm interested in this property"
}
```

### GET /api/v1/bot/suggestions
Get role-specific conversation starters.

**Response:**
```json
{
  "suggestions": [
    "Find 2-bedroom apartments under $2000",
    "How do I apply for a rental?",
    "What documents do I need?"
  ]
}
```

### GET /api/v1/bot/faqs
Retrieve frequently asked questions and tips.

### POST /api/v1/bot/feedback
Submit feedback about bot responses.

## Integration with Existing System

### Automatic Bot Responses
The bot automatically responds to messages in conversations when:
- User mentions "bot", "help", "assistant", or "ofie"
- Message contains question words (how, what, when, where, why)
- Message ends with a question mark
- User asks for help or assistance

### Conversation Integration
Bots can participate in regular conversations alongside human users, providing assistance when needed without interrupting natural conversation flow.

## Knowledge Base

The bot's knowledge includes:
- **Property Information**: Types, amenities, search criteria
- **Rental Process**: Applications, requirements, documentation
- **Maintenance**: Categories, emergency vs. routine, reporting process
- **Payments**: Methods, schedules, troubleshooting
- **Platform Features**: Navigation, tools, capabilities
- **Role-specific Tips**: Tailored advice for tenants and landlords

## Setup and Deployment

### Database Migration
```bash
rails db:migrate
```

### Seed Bot User
```bash
rails db:seed
```

### Environment Variables
No additional environment variables required for basic functionality.

## Testing

### Run Bot Tests
```bash
# Model tests
rails test test/models/bot_test.rb

# Service tests
rails test test/services/bot_service_test.rb

# Controller tests
rails test test/controllers/api/bot_controller_test.rb

# All bot-related tests
rails test test/models/bot_test.rb test/services/bot_service_test.rb test/controllers/api/bot_controller_test.rb
```

### Test Coverage
- Model validations and associations
- Service intent classification and response generation
- API endpoint functionality
- Error handling and edge cases
- Authentication and authorization

## Usage Examples

### For Tenants
- "Find me a 2-bedroom apartment under $2000"
- "How do I apply for this rental?"
- "What documents do I need?"
- "My sink is broken, how do I report it?"
- "How do I pay my rent online?"

### For Landlords
- "How do I list a new property?"
- "How do I review rental applications?"
- "How do I manage maintenance requests?"
- "What are the platform fees?"
- "How do I communicate with tenants?"

## Customization and Extension

### Adding New Intents
1. Update `BotService#classify_intent` method
2. Add corresponding response logic in `BotService#generate_response`
3. Update knowledge base if needed
4. Add tests for new functionality

### Expanding Knowledge Base
1. Update `KnowledgeBase` module with new information
2. Ensure responses reference new knowledge appropriately
3. Test with relevant queries

### Custom Quick Actions
1. Modify `BotService#generate_quick_actions` method
2. Add role-specific or context-specific actions
3. Ensure frontend can handle new action types

## Monitoring and Analytics

### Logging
- All bot interactions are logged for analysis
- Error handling includes detailed logging
- Feedback collection for continuous improvement

### Metrics to Track
- Query volume and patterns
- Intent classification accuracy
- User satisfaction (through feedback)
- Escalation to human support rates
- Response times

## Troubleshooting

### Common Issues

**Bot not responding:**
- Check if bot user exists in database
- Verify bot is active (`Bot.primary_bot.active?`)
- Check application logs for errors

**Incorrect intent classification:**
- Review query patterns in `BotService#classify_intent`
- Add more keywords or patterns for specific intents
- Consider adjusting confidence thresholds

**Missing knowledge:**
- Update `KnowledgeBase` module
- Ensure responses cover new scenarios
- Add fallback responses for unknown queries

### Debug Commands
```ruby
# Check bot status
Bot.primary_bot

# Test bot service
service = BotService.new(user: User.first, query: "test", conversation: Conversation.first)
response = service.process_query

# Check recent bot conversations
Conversation.joins(:messages).where(messages: { sender: Bot.primary_bot }).recent
```

## Security Considerations

- Bot user has minimal permissions
- All API endpoints require authentication
- Bot responses don't expose sensitive information
- Input validation prevents injection attacks
- Rate limiting should be implemented for bot endpoints

## Future Enhancements

- Machine learning integration for improved intent recognition
- Multi-language support
- Voice interaction capabilities
- Advanced analytics and reporting
- Integration with external services (weather, local information)
- Personalized responses based on user history

## Support

For technical issues or questions about the bot functionality:
1. Check this documentation
2. Review application logs
3. Run diagnostic commands
4. Contact the development team

---

*This documentation is maintained alongside the bot codebase and should be updated when functionality changes.*