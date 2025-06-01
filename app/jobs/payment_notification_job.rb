class PaymentNotificationJob < ApplicationJob
  queue_as :default

  def perform(payment, notification_type)
    case notification_type
    when "payment_succeeded"
      send_payment_success_notification(payment)
    when "payment_failed"
      send_payment_failure_notification(payment)
    when "payment_due_reminder"
      send_payment_due_reminder(payment)
    when "payment_overdue"
      send_payment_overdue_notification(payment)
    else
      Rails.logger.warn "Unknown payment notification type: #{notification_type}"
    end
  rescue => e
    Rails.logger.error "Failed to send payment notification: #{e.message}"
    raise e
  end

  private

  def send_payment_success_notification(payment)
    # Send email to tenant
    PaymentMailer.payment_success(payment).deliver_now

    # Create in-app notification
    Notification.create!(
      user: payment.user,
      title: "Payment Successful",
      message: "Your #{payment.payment_type} payment of $#{payment.amount} has been processed successfully.",
      notification_type: "payment_success",
      data: {
        payment_id: payment.id,
        amount: payment.amount,
        payment_type: payment.payment_type
      }
    )

    # Notify landlord for rent payments
    if payment.rent_payment?
      Notification.create!(
        user: payment.lease_agreement.landlord,
        title: "Rent Payment Received",
        message: "Rent payment of $#{payment.amount} received from #{payment.user.name}.",
        notification_type: "payment_received",
        data: {
          payment_id: payment.id,
          tenant_name: payment.user.name,
          amount: payment.amount
        }
      )
    end
  end

  def send_payment_failure_notification(payment)
    # Send email to tenant
    PaymentMailer.payment_failed(payment).deliver_now

    # Create in-app notification
    Notification.create!(
      user: payment.user,
      title: "Payment Failed",
      message: "Your #{payment.payment_type} payment of $#{payment.amount} could not be processed. Please update your payment method and try again.",
      notification_type: "payment_failed",
      data: {
        payment_id: payment.id,
        amount: payment.amount,
        payment_type: payment.payment_type,
        failure_reason: payment.failure_reason
      }
    )
  end

  def send_payment_due_reminder(payment)
    # Send email reminder
    PaymentMailer.payment_due_reminder(payment).deliver_now

    # Create in-app notification
    Notification.create!(
      user: payment.user,
      title: "Payment Due Soon",
      message: "Your #{payment.payment_type} payment of $#{payment.amount} is due on #{payment.due_date.strftime('%B %d, %Y')}.",
      notification_type: "payment_due",
      data: {
        payment_id: payment.id,
        amount: payment.amount,
        payment_type: payment.payment_type,
        due_date: payment.due_date
      }
    )
  end

  def send_payment_overdue_notification(payment)
    # Send email notification
    PaymentMailer.payment_overdue(payment).deliver_now

    # Create in-app notification
    days_overdue = payment.days_overdue
    Notification.create!(
      user: payment.user,
      title: "Payment Overdue",
      message: "Your #{payment.payment_type} payment of $#{payment.amount} is #{days_overdue} day#{'s' if days_overdue != 1} overdue. Please make payment immediately to avoid late fees.",
      notification_type: "payment_overdue",
      data: {
        payment_id: payment.id,
        amount: payment.amount,
        payment_type: payment.payment_type,
        days_overdue: days_overdue,
        due_date: payment.due_date
      }
    )

    # Notify landlord for rent payments
    if payment.rent_payment?
      Notification.create!(
        user: payment.lease_agreement.landlord,
        title: "Overdue Rent Payment",
        message: "Rent payment from #{payment.user.name} is #{days_overdue} day#{'s' if days_overdue != 1} overdue.",
        notification_type: "rent_overdue",
        data: {
          payment_id: payment.id,
          tenant_name: payment.user.name,
          amount: payment.amount,
          days_overdue: days_overdue
        }
      )
    end
  end
end
