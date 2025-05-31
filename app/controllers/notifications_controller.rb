class NotificationsController < ApplicationController
  before_action :authenticate_request
  before_action :set_notification, only: [ :show, :mark_read ]

  # GET /notifications
  # GET /notifications.json
  def index
    @notifications = current_user.notifications
                                 .order(created_at: :desc)
                                 .limit(50)

    @unread_count = current_user.notifications.where(read: false).count

    respond_to do |format|
      format.html
      format.json do
        render json: {
          notifications: @notifications.map do |notification|
            {
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.notification_type,
              read: notification.read,
              created_at: notification.created_at,
              url: notification.url
            }
          end,
          unread_count: @unread_count
        }
      end
    end
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
    # Mark as read when viewed
    @notification.update(read: true) unless @notification.read?

    respond_to do |format|
      format.html { redirect_to @notification.url if @notification.url.present? }
      format.json { render json: @notification }
    end
  end

  # PATCH /notifications/1/mark_read
  def mark_read
    @notification.update(read: true)

    respond_to do |format|
      format.json { render json: { status: "success", message: "Notification marked as read" } }
      format.html { redirect_back(fallback_location: notifications_path) }
    end
  end

  # PATCH /notifications/mark_all_read
  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("notifications-list",
            partial: "notifications/list",
            locals: { notifications: current_user.notifications.recent.limit(20) }
          ),
          turbo_stream.replace("unread-count",
            partial: "notifications/unread_count",
            locals: { count: 0 }
          )
        ]
      end
    end
  end

  def unread_count
    count = current_user.notifications.unread.count
    render json: { count: count }
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: "Notification not found" }, status: :not_found }
      format.html { redirect_to notifications_path, alert: "Notification not found" }
    end
  end
end
