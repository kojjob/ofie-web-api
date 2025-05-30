class ConversationsController < ApplicationController
  before_action :authenticate_request
  before_action :set_conversation, only: [ :show, :update, :destroy ]
  before_action :authorize_conversation_access, only: [ :show, :update, :destroy ]

  # GET /conversations
  # GET /conversations.json
  def index
    @conversations = current_user.conversations
                                .includes(:landlord, :tenant, :property, :messages)
                                .recent
                                .limit(50)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          conversations: @conversations.map do |conversation|
            {
              id: conversation.id,
              subject: conversation.subject,
              status: conversation.status,
              property: {
                id: conversation.property.id,
                title: conversation.property.title,
                address: conversation.property.address
              },
              other_participant: {
                id: conversation.other_participant(current_user).id,
                name: conversation.other_participant(current_user).name,
                email: conversation.other_participant(current_user).email
              },
              last_message_at: conversation.last_message_at,
              unread_count: conversation.unread_count_for(current_user),
              last_message: conversation.messages.last&.content&.truncate(50)
            }
          end
        }
      end
    end
  end

  # GET /conversations/1
  # GET /conversations/1.json
  def show
    @messages = @conversation.messages
                            .includes(:sender)
                            .order(created_at: :asc)
                            .limit(100)

    # Mark messages as read for current user
    @conversation.mark_as_read_for(current_user)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          conversation: {
            id: @conversation.id,
            subject: @conversation.subject,
            status: @conversation.status,
            property: {
              id: @conversation.property.id,
              title: @conversation.property.title,
              address: @conversation.property.address
            },
            other_participant: {
              id: @conversation.other_participant(current_user).id,
              name: @conversation.other_participant(current_user).name,
              email: @conversation.other_participant(current_user).email
            }
          },
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
              read: message.read
            }
          end
        }
      end
    end
  end

  # POST /conversations
  # POST /conversations.json
  def create
    @property = Property.find(conversation_params[:property_id])
    @other_user = User.find(conversation_params[:other_user_id])

    unless current_user.can_message?(@other_user, @property)
      respond_to do |format|
        format.html { redirect_to properties_path, alert: "You cannot start a conversation with this user." }
        format.json { render json: { error: "Unauthorized to start conversation" }, status: :forbidden }
      end
      return
    end

    # Check if conversation already exists
    @conversation = current_user.conversation_with(@other_user, @property)

    if @conversation
      respond_to do |format|
        format.html { redirect_to @conversation }
        format.json { render json: { conversation_id: @conversation.id }, status: :ok }
      end
      return
    end

    # Create new conversation
    @conversation = Conversation.new(
      landlord: current_user.landlord? ? current_user : @other_user,
      tenant: current_user.tenant? ? current_user : @other_user,
      property: @property,
      subject: conversation_params[:subject] || "Inquiry about #{@property.title}",
      status: "active"
    )

    respond_to do |format|
      if @conversation.save
        format.html { redirect_to @conversation, notice: "Conversation was successfully created." }
        format.json { render json: { conversation_id: @conversation.id }, status: :created }
      else
        format.html { redirect_to @property, alert: @conversation.errors.full_messages.join(", ") }
        format.json { render json: { errors: @conversation.errors }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /conversations/1
  # PATCH/PUT /conversations/1.json
  def update
    respond_to do |format|
      if @conversation.update(conversation_update_params)
        format.html { redirect_to @conversation, notice: "Conversation was successfully updated." }
        format.json { render json: { status: "updated" }, status: :ok }
      else
        format.html { render :show }
        format.json { render json: { errors: @conversation.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /conversations/1
  # DELETE /conversations/1.json
  def destroy
    @conversation.destroy
    respond_to do |format|
      format.html { redirect_to conversations_url, notice: "Conversation was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def authorize_conversation_access
    unless @conversation.landlord == current_user || @conversation.tenant == current_user
      respond_to do |format|
        format.html { redirect_to conversations_path, alert: "Access denied." }
        format.json { render json: { error: "Access denied" }, status: :forbidden }
      end
    end
  end

  def conversation_params
    params.require(:conversation).permit(:subject, :property_id, :other_user_id)
  end

  def conversation_update_params
    params.require(:conversation).permit(:status)
  end

  # GET /conversations/new
  def new
    @property = Property.find(params[:property_id]) if params[:property_id]
    @conversation = Conversation.new
  end
end
