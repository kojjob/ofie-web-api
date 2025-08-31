class MessagesController < ApplicationController
  before_action :authenticate_request
  before_action :set_conversation
  before_action :authorize_conversation_access
  before_action :set_message, only: [ :show, :update, :destroy ]

  # GET /conversations/:conversation_id/messages
  # GET /conversations/:conversation_id/messages.json
  def index
    @messages = @conversation.messages
                            .includes(:sender)
                            .order(created_at: :asc)
                            .page(params[:page])
                            .per(50)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          messages: @messages.map do |message|
            {
              id: message.id,
              content: message.content,
              message_type: message.message_type,
              sender: {
                id: message.sender.id,
                name: message.sender.name,
                email: message.sender.email
              },
              created_at: message.created_at,
              read: message.read,
              attachment_url: message.attachment_url
            }
          end,
          pagination: {
            current_page: @messages.current_page,
            total_pages: @messages.total_pages,
            total_count: @messages.total_count
          }
        }
      end
    end
  end

  # GET /conversations/:conversation_id/messages/1
  # GET /conversations/:conversation_id/messages/1.json
  def show
    respond_to do |format|
      format.html
      format.json do
        render json: {
          id: @message.id,
          content: @message.content,
          message_type: @message.message_type,
          sender: {
            id: @message.sender.id,
            name: @message.sender.name,
            email: @message.sender.email
          },
          created_at: @message.created_at,
          read: @message.read,
          attachment_url: @message.attachment_url
        }
      end
    end
  end

  # POST /conversations/:conversation_id/messages
  # POST /conversations/:conversation_id/messages.json
  def create
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    respond_to do |format|
      if @message.save
        # Check if bot should respond
        bot_response = check_for_bot_response(@message)

        format.html { redirect_to @conversation, notice: "Message was successfully sent." }
        format.json do
          response_data = {
            message: {
              id: @message.id,
              content: @message.content,
              message_type: @message.message_type,
              sender: {
                id: @message.sender.id,
                name: @message.sender.name,
                email: @message.sender.email
              },
              created_at: @message.created_at,
              read: @message.read
            }
          }

          # Include bot response if generated
          if bot_response
            response_data[:bot_response] = {
              id: bot_response.id,
              content: bot_response.content,
              sender: {
                id: bot_response.sender.id,
                name: bot_response.sender.name,
                role: bot_response.sender.role
              },
              created_at: bot_response.created_at
            }
          end

          render json: response_data, status: :created
        end
      else
        format.html { redirect_to @conversation, alert: @message.errors.full_messages.join(", ") }
        format.json { render json: { errors: @message.errors }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /conversations/:conversation_id/messages/1
  # PATCH/PUT /conversations/:conversation_id/messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_update_params)
        format.html { redirect_to @conversation, notice: "Message was successfully updated." }
        format.json { render json: { status: "updated" }, status: :ok }
      else
        format.html { redirect_to @conversation, alert: @message.errors.full_messages.join(", ") }
        format.json { render json: { errors: @message.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /conversations/:conversation_id/messages/1
  # DELETE /conversations/:conversation_id/messages/1.json
  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to @conversation, notice: "Message was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # PATCH /conversations/:conversation_id/messages/1/mark_read
  def mark_read
    @message.mark_as_read!
    respond_to do |format|
      format.html { redirect_to @conversation }
      format.json { render json: { status: "marked_as_read" }, status: :ok }
    end
  end

  # PATCH /conversations/:conversation_id/messages/mark_all_read
  def mark_all_read
    @conversation.mark_as_read_for(current_user)
    respond_to do |format|
      format.html { redirect_to @conversation }
      format.json { render json: { status: "all_marked_as_read" }, status: :ok }
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def set_message
    @message = @conversation.messages.find(params[:id])
  end

  def authorize_conversation_access
    unless @conversation.landlord == current_user || @conversation.tenant == current_user
      respond_to do |format|
        format.html { redirect_to conversations_path, alert: "Access denied." }
        format.json { render json: { error: "Access denied" }, status: :forbidden }
      end
    end
  end

  def message_params
    params.require(:message).permit(:content, :message_type, :attachment_url)
  end

  def message_update_params
    params.require(:message).permit(:read)
  end

  def check_for_bot_response(message)
    # Check if bot should respond to this message
    bot = Bot.primary_bot
    return nil unless bot

    # Don't respond to bot's own messages
    return nil if message.sender.bot?

    # Check if message mentions bot or contains help keywords
    content = message.content.downcase
    should_respond = content.include?("bot") ||
                    content.include?("help") ||
                    content.include?("assistant") ||
                    content.include?("ofie") ||
                    content.include?("?") || # Questions
                    content.match?(/\b(how|what|when|where|why|can|could|would|should)\b/)

    if should_respond
      # Generate bot response using BotService
      bot_response = BotService.new(
        user: message.sender,
        query: message.content,
        conversation: @conversation
      ).process_query

      # Create bot message
      bot_message = @conversation.messages.create!(
        sender: bot,
        content: bot_response[:response],
        message_type: "text"
      )

      return bot_message
    end

    nil
  rescue => e
    Rails.logger.error "Bot response error: #{e.message}"
    nil
  end
end
