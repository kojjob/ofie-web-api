class CreateBotUser < ActiveRecord::Migration[8.0]
  def up
    # Create the primary bot user
    bot = User.create!(
      name: "Ofie Assistant",
      email: "bot@ofie.com",
      password: SecureRandom.hex(32), # Random secure password
      role: "bot",
      email_verified: true
    )

    puts "Created bot user with ID: #{bot.id}"
  end

  def down
    # Remove the bot user
    bot = User.find_by(email: "bot@ofie.com", role: "bot")
    if bot
      # Delete all conversations and messages involving the bot
      Conversation.where("landlord_id = ? OR tenant_id = ?", bot.id, bot.id).destroy_all
      Message.where(sender_id: bot.id).destroy_all

      # Delete the bot user
      bot.destroy
      puts "Removed bot user"
    end
  end
end
