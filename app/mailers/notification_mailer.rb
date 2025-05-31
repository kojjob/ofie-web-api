# Mailer for sending notification emails
class NotificationMailer < ApplicationMailer
  default from: "notifications@ofie.com"

  def maintenance_request_created(notification)
    @notification = notification
    @maintenance_request = notification.notifiable
    @user = notification.user
    @tenant = @maintenance_request.tenant
    @property = @maintenance_request.property

    mail(
      to: @user.email,
      subject: "New Maintenance Request - #{@property.title}"
    )
  end

  def maintenance_request_updated(notification)
    @notification = notification
    @maintenance_request = notification.notifiable
    @user = notification.user
    @property = @maintenance_request.property

    mail(
      to: @user.email,
      subject: "Maintenance Request Updated - #{@property.title}"
    )
  end

  def maintenance_request_assigned(notification)
    @notification = notification
    @maintenance_request = notification.notifiable
    @user = notification.user
    @property = @maintenance_request.property
    @assigned_to = @maintenance_request.assigned_to

    mail(
      to: @user.email,
      subject: "Maintenance Request Assignment - #{@property.title}"
    )
  end

  def maintenance_request_completed(notification)
    @notification = notification
    @maintenance_request = notification.notifiable
    @user = notification.user
    @property = @maintenance_request.property

    mail(
      to: @user.email,
      subject: "Maintenance Request Completed - #{@property.title}"
    )
  end

  def generic_notification(notification)
    @notification = notification
    @user = notification.user

    mail(
      to: @user.email,
      subject: @notification.title
    )
  end
end
