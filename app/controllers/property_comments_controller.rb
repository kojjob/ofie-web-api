class PropertyCommentsController < ApplicationController
  before_action :authenticate_request, except: [ :index ]
  before_action :set_property, only: [ :index, :create ]
  before_action :set_comment, only: [ :show, :edit, :update, :destroy, :toggle_like, :flag ]
  before_action :ensure_can_edit, only: [ :edit, :update ]
  before_action :ensure_can_delete, only: [ :destroy ]

  # GET /properties/:property_id/comments
  def index
    @comments = @property.property_comments
                        .not_flagged
                        .includes(:user, :comment_likes, replies: [ :user, :comment_likes ])
                        .top_level
                        .recent
                        .limit(10)

    @new_comment = PropertyComment.new if user_signed_in?

    respond_to do |format|
      format.html
      format.json {
        render json: {
          comments: comments_json(@comments),
          total_comments: @property.comments_count
        }
      }
    end
  end

  # GET /property_comments/:id
  def show
    @property = @comment.property

    respond_to do |format|
      format.html
      format.json { render json: { comment: comment_json(@comment) } }
    end
  end

  # POST /properties/:property_id/comments
  def create
    @comment = @property.property_comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        # Create notification for property owner
        create_comment_notification(@comment) unless current_user == @property.user

        format.html {
          redirect_to property_property_comments_path(@property),
          notice: "Comment was successfully posted."
        }
        format.json {
          render json: {
            message: "Comment posted successfully",
            comment: comment_json(@comment)
          }, status: :created
        }
      else
        format.html {
          @comments = @property.property_comments
                              .not_flagged
                              .includes(:user, replies: :user)
                              .top_level
                              .recent
                              .limit(10)
          @new_comment = @comment  # Use the failed comment to show validation errors
          render :index, status: :unprocessable_entity
        }
        format.json {
          render json: {
            error: "Failed to post comment",
            details: @comment.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # GET /property_comments/:id/edit
  def edit
    @property = @comment.property
  end

  # PATCH/PUT /property_comments/:id
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        @comment.mark_as_edited!

        format.html {
          redirect_to property_property_comments_path(@comment.property),
          notice: "Comment was successfully updated."
        }
        format.json {
          render json: {
            message: "Comment updated successfully",
            comment: comment_json(@comment)
          }
        }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json {
          render json: {
            error: "Failed to update comment",
            details: @comment.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # DELETE /property_comments/:id
  def destroy
    property = @comment.property
    @comment.destroy!

    respond_to do |format|
      format.html {
        redirect_to property_property_comments_path(property),
        notice: "Comment was successfully deleted."
      }
      format.json {
        render json: { message: "Comment deleted successfully" }
      }
    end
  end

  # POST /property_comments/:id/toggle_like
  def toggle_like
    liked = @comment.toggle_like!(current_user)

    respond_to do |format|
      format.html { redirect_back(fallback_location: @comment.property) }
      format.json {
        render json: {
          liked: liked,
          likes_count: @comment.likes_count,
          message: liked ? "Comment liked" : "Comment unliked"
        }
      }
    end
  end

  # POST /property_comments/:id/flag
  def flag
    reason = params[:reason] || "Inappropriate content"

    if @comment.flag!(reason, current_user)
      respond_to do |format|
        format.html {
          redirect_back(
            fallback_location: @comment.property,
            notice: "Comment has been flagged for review."
          )
        }
        format.json {
          render json: { message: "Comment flagged successfully" }
        }
      end
    else
      respond_to do |format|
        format.html {
          redirect_back(
            fallback_location: @comment.property,
            alert: "Unable to flag comment."
          )
        }
        format.json {
          render json: { error: "Failed to flag comment" },
          status: :unprocessable_entity
        }
      end
    end
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_comment
    @comment = PropertyComment.find(params[:id])
  end

  def comment_params
    params.require(:property_comment).permit(:content, :parent_id)
  end

  def ensure_can_edit
    unless @comment.can_be_edited_by?(current_user)
      respond_to do |format|
        format.html {
          redirect_back(
            fallback_location: @comment.property,
            alert: "You can only edit your own comments within 15 minutes of posting."
          )
        }
        format.json {
          render json: { error: "Unauthorized" },
          status: :forbidden
        }
      end
    end
  end

  def ensure_can_delete
    unless @comment.can_be_deleted_by?(current_user)
      respond_to do |format|
        format.html {
          redirect_back(
            fallback_location: @comment.property,
            alert: "You don't have permission to delete this comment."
          )
        }
        format.json {
          render json: { error: "Unauthorized" },
          status: :forbidden
        }
      end
    end
  end

  def create_comment_notification(comment)
    Notification.create!(
      user: comment.property.user,
      title: "New Comment",
      message: "#{comment.user.name || comment.user.email} commented on your property '#{comment.property.title}'",
      notification_type: "comment",
      notifiable: comment,
      url: property_property_comments_path(comment.property)
    )
  end

  def comment_json(comment, include_replies: true)
    result = {
      id: comment.id,
      content: comment.display_content,
      user: {
        id: comment.user.id,
        name: comment.user.name || comment.user.email.split("@").first,
        email: comment.user.email
      },
      likes_count: comment.likes_count,
      liked_by_current_user: comment.liked_by?(current_user),
      can_edit: comment.can_be_edited_by?(current_user),
      can_delete: comment.can_be_deleted_by?(current_user),
      edited: comment.edited?,
      edited_at: comment.edited_at,
      created_at: comment.created_at
    }

    # Only include replies if requested and if replies are already loaded to avoid N+1
    if include_replies && comment.association(:replies).loaded?
      result[:replies] = comment.replies.not_flagged.map { |reply| comment_json(reply, include_replies: false) }
    elsif include_replies
      # If replies aren't loaded, load them with proper includes
      result[:replies] = comment.replies.not_flagged.includes(:user, :comment_likes).map { |reply| comment_json(reply, include_replies: false) }
    end

    result
  end

  def comments_json(comments)
    comments.map { |comment| comment_json(comment) }
  end
end
