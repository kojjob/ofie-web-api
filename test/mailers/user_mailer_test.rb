require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def setup
    @user = create(:user, :tenant, :with_email_verification, :with_password_reset)
  end

  test "email_verification" do
    mail = UserMailer.email_verification(@user)
    assert_equal "Please verify your email address", mail.subject
    assert_equal [ @user.email ], mail.to
    assert_equal [ "noreply@ofie.com" ], mail.from
    assert_match "verify", mail.body.encoded
  end

  test "password_reset" do
    mail = UserMailer.password_reset(@user)
    assert_equal "Reset your password", mail.subject
    assert_equal [ @user.email ], mail.to
    assert_equal [ "noreply@ofie.com" ], mail.from
    assert_match "reset", mail.body.encoded
  end
end
