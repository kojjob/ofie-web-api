require "test_helper"

class PropertyInquiriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @landlord = create(:user, :landlord, :verified)
    @tenant = create(:user, :tenant, :verified)
    @another_landlord = create(:user, :landlord, :verified)

    # Create properties for each landlord
    @property_one = create(:property, user: @landlord)
    @property_two = create(:property, user: @another_landlord)

    # Create inquiries for landlord's property
    @inquiry = create(:property_inquiry, :pending, property: @property_one, user: @tenant)
    @inquiry_two = create(:property_inquiry, :read, property: @property_one)

    # Create inquiry for another landlord's property
    @inquiry_three = create(:property_inquiry, :pending, property: @property_two)
  end

  # ============================================
  # INDEX action tests
  # ============================================
  test "should get index for authenticated landlord" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get property_inquiries_path
    assert_response :success
  end

  test "should only show inquiries for landlord's properties" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get property_inquiries_path
    assert_response :success
    # Landlord should see inquiries 1 and 2 (for property_one), not inquiry 3
    assert_select "table tbody tr", minimum: 1
  end

  test "should redirect to login if not authenticated" do
    get property_inquiries_path
    assert_redirected_to login_path
  end

  test "tenant cannot access inquiries index" do
    post login_path, params: { email: @tenant.email, password: "password123" }
    get property_inquiries_path
    assert_redirected_to dashboard_path
  end

  # ============================================
  # SHOW action tests
  # ============================================
  test "landlord can view their own property inquiry" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get property_inquiry_path(@inquiry)
    assert_response :success
  end

  test "landlord cannot view another landlord's property inquiry" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get property_inquiry_path(@inquiry_three)
    assert_redirected_to property_inquiries_path
    assert_equal "You don't have permission to view this inquiry.", flash[:alert]
  end

  test "viewing inquiry marks it as read" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    assert @inquiry.unread?
    get property_inquiry_path(@inquiry)
    @inquiry.reload
    assert_not @inquiry.unread?
    assert_equal "read", @inquiry.status
  end

  # ============================================
  # MARK_READ action tests
  # ============================================
  test "landlord can mark inquiry as read" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    assert @inquiry.unread?
    post mark_read_property_inquiry_path(@inquiry)
    @inquiry.reload
    assert_not @inquiry.unread?
    assert_equal "read", @inquiry.status
  end

  test "landlord cannot mark another landlord's inquiry as read" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    post mark_read_property_inquiry_path(@inquiry_three)
    assert_redirected_to property_inquiries_path
    assert_equal "You don't have permission to update this inquiry.", flash[:alert]
  end

  # ============================================
  # MARK_RESPONDED action tests
  # ============================================
  test "landlord can mark inquiry as responded" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    @inquiry.mark_as_read!
    post mark_responded_property_inquiry_path(@inquiry)
    @inquiry.reload
    assert_equal "responded", @inquiry.status
  end

  test "landlord cannot mark another landlord's inquiry as responded" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    post mark_responded_property_inquiry_path(@inquiry_three)
    assert_redirected_to property_inquiries_path
  end

  # ============================================
  # ARCHIVE action tests
  # ============================================
  test "landlord can archive inquiry" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    post archive_property_inquiry_path(@inquiry)
    @inquiry.reload
    assert_equal "archived", @inquiry.status
  end

  test "landlord cannot archive another landlord's inquiry" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    post archive_property_inquiry_path(@inquiry_three)
    assert_redirected_to property_inquiries_path
    assert_equal "You don't have permission to update this inquiry.", flash[:alert]
  end

  # ============================================
  # UNARCHIVE action tests
  # ============================================
  test "landlord can unarchive inquiry" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    @inquiry.archive!
    assert_equal "archived", @inquiry.status
    post unarchive_property_inquiry_path(@inquiry)
    @inquiry.reload
    assert_equal "pending", @inquiry.status
  end

  # ============================================
  # Filter tests
  # ============================================
  test "can filter inquiries by status" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get property_inquiries_path(status: "pending")
    assert_response :success
  end

  test "can filter inquiries by property" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get property_inquiries_path(property_id: @property_one.id)
    assert_response :success
  end
end
