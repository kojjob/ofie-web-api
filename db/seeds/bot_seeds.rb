# AI-generated code: Seeds for bot functionality

puts "Creating bot user..."

# Create the primary bot user if it doesn't exist
bot = Bot.find_or_create_by(email: "bot@ofie.com") do |b|
  b.name = "Ofie Assistant"
  b.password = SecureRandom.hex(32)
  b.role = "bot"
  b.email_verified = true
end

if bot.persisted?
  puts "✓ Bot user created/found: #{bot.name} (#{bot.email})"
else
  puts "✗ Failed to create bot user: #{bot.errors.full_messages.join(', ')}"
end

# Create some sample conversations with the bot for development
if Rails.env.development?
  puts "Creating sample bot conversations..."

  # Find or create sample users
  tenant = User.find_or_create_by(email: "tenant@example.com") do |u|
    u.name = "Sample Tenant"
    u.password = "password123"
    u.role = "tenant"
    u.email_verified = true
  end

  landlord = User.find_or_create_by(email: "landlord@example.com") do |u|
    u.name = "Sample Landlord"
    u.password = "password123"
    u.role = "landlord"
    u.email_verified = true
  end

  # Find or create a sample property
  property = Property.find_or_create_by(title: "Sample Property for Bot Demo") do |p|
    p.user = landlord
    p.description = "A beautiful 2-bedroom apartment perfect for testing bot functionality"
    p.address = "123 Bot Street, AI City, TC 12345"
    p.price = 1500.00
    p.bedrooms = 2
    p.bathrooms = 1
    p.square_feet = 900
    p.property_type = "apartment"
    p.availability_status = "available"
    p.status = "active"
  end

  # Create sample conversation between tenant and bot
  conversation = Conversation.find_or_create_by(
    landlord: bot,
    tenant: tenant,
    property_id: property.id
  ) do |c|
    c.subject = "Chat with Ofie Assistant"
    c.status = "active"
  end

  if conversation.persisted? && conversation.messages.empty?
    # Create sample messages
    messages = [
      {
        sender: tenant,
        content: "Hi, I'm interested in the 2-bedroom apartment. Can you tell me more about it?"
      },
      {
        sender: bot,
        content: "Hello! I'd be happy to help you learn more about this property. This is a beautiful 2-bedroom, 1-bathroom apartment with 900 square feet of living space, priced at $1,500 per month. Would you like to know about the application process, schedule a viewing, or do you have specific questions about the property?"
      },
      {
        sender: tenant,
        content: "What documents do I need to apply?"
      },
      {
        sender: bot,
        content: "For a rental application, you'll typically need: 1) Government-issued ID, 2) Proof of income (pay stubs, employment letter, or tax returns), 3) Bank statements, 4) References from previous landlords, 5) Completed rental application form. Some landlords may also require a credit check authorization. Would you like me to help you start the application process?"
      }
    ]

    messages.each do |msg_data|
      Message.create!(
        conversation: conversation,
        sender: msg_data[:sender],
        content: msg_data[:content],
        message_type: 'text'
      )
    end

    puts "✓ Sample bot conversation created with #{messages.length} messages"
  end

  # Create another conversation between landlord and bot
  landlord_conversation = Conversation.find_or_create_by(
    landlord: landlord,
    tenant: bot,
    property_id: property.id
  ) do |c|
    c.subject = "Landlord Chat with Ofie Assistant"
    c.status = "active"
  end

  if landlord_conversation.persisted? && landlord_conversation.messages.empty?
    landlord_messages = [
      {
        sender: landlord,
        content: "How do I manage maintenance requests efficiently?"
      },
      {
        sender: bot,
        content: "Great question! Here are some tips for managing maintenance requests: 1) Set up automated notifications for new requests, 2) Categorize requests by urgency (emergency vs. routine), 3) Maintain a list of trusted contractors, 4) Use our platform's maintenance tracking features, 5) Respond to tenants promptly with status updates. Would you like me to show you how to access the maintenance management tools?"
      }
    ]

    landlord_messages.each do |msg_data|
      Message.create!(
        conversation: landlord_conversation,
        sender: msg_data[:sender],
        content: msg_data[:content],
        message_type: 'text'
      )
    end

    puts "✓ Sample landlord-bot conversation created"
  end
end

puts "Bot seeding completed!"
