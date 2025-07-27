class MessageMailer < ApplicationMailer
  default from: "noreply@ofie.com"

  def new_message_notification(message)
    @message = message
    @conversation = message.conversation
    @sender = message.sender
    @recipient = message.recipient
    @property = @conversation.property

    mail(
      to: @recipient.email,
      subject: "New message from #{@sender.name || @sender.email} about #{@property.title}"
    )
  end

  def conversation_started_notification(conversation)
    @conversation = conversation
    @property = conversation.property
    @landlord = conversation.landlord
    @tenant   = conversation.tenant

    # Send to landlord
    mail(
      to: @landlord.email,
      subject: "New conversation started about #{@property.title}"
    )
  end
end
