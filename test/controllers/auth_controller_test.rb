require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "should get register" do
    get register_url
    assert_response :success
  end

  test "should get login" do
    get login_url
    assert_response :success
  end
end
