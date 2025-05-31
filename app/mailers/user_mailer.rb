class UserMailer < ApplicationMailer
  default from: "noreply@ofie.com"

  def email_verification(user)
    @user = user
    @verification_url = verify_email_url(token: @user.email_verification_token)

    mail(
      to: @user.email,
      subject: "Please verify your email address"
    )
  end

  def password_reset(user)
    @user = user
    @reset_url = reset_password_url(token: @user.password_reset_token, host: Rails.application.config.action_mailer.default_url_options[:host], port: Rails.application.config.action_mailer.default_url_options[:port])

    mail(
      to: @user.email,
      subject: "Reset your password"
    )
  end
end
