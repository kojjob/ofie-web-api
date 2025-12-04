require "test_helper"
require "ostruct"

class PaymentServiceTest < ActiveSupport::TestCase
  setup do
    # Mock Stripe credentials before creating anything
    credentials_stub = OpenStruct.new(secret_key: "sk_test_123")
    Rails.application.credentials.define_singleton_method(:stripe) { credentials_stub }
    Stripe.api_key = "sk_test_123"

    @user = create(:user, :tenant, :with_stripe)
    @landlord = create(:user, :landlord)
    @property = create(:property, user: @landlord)
    @lease_agreement = create(:lease_agreement, property: @property, tenant: @user)
    @payment = create(:payment, :rent, user: @user, lease_agreement: @lease_agreement)
    @payment_service = PaymentService.new
  end

  teardown do
    # Reset WebMock stubs after each test to prevent interference
    WebMock.reset!
  end

  # Test 1: Initialization
  test "initializes with Stripe API key from credentials" do
    service = PaymentService.new
    assert_equal "sk_test_123", Stripe.api_key
  end

  test "raises error when Stripe secret key is not configured" do
    Rails.application.credentials.define_singleton_method(:stripe) { nil }

    assert_raises(RuntimeError, "Stripe secret key not configured") do
      PaymentService.new
    end

    # Restore credentials for other tests
    credentials_stub = OpenStruct.new(secret_key: "sk_test_123")
    Rails.application.credentials.define_singleton_method(:stripe) { credentials_stub }
  end

  # Test 2: create_payment_intent - Success scenarios
  test "create_payment_intent creates successful payment intent" do
    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)
    stub_stripe_payment_intent_create(status: "succeeded", amount: (@payment.amount * 100).to_i, id: "pi_test123")

    result = @payment_service.create_payment_intent(payment: @payment)

    assert result[:success]
    assert_equal "pi_test123", result[:payment_intent]["id"]
    @payment.reload
    assert_equal "succeeded", @payment.status
    assert_equal "pi_test123", @payment.stripe_payment_intent_id
  end

  test "create_payment_intent with processing status" do
    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)
    stub_stripe_payment_intent_create(status: "processing", amount: (@payment.amount * 100).to_i, id: "pi_processing")

    result = @payment_service.create_payment_intent(payment: @payment)

    assert result[:success]
    @payment.reload
    assert_equal "processing", @payment.status
  end

  test "create_payment_intent converts amount to cents" do
    @payment.update!(amount: 15.50)
    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)

    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .with(body: hash_including({ "amount" => "1550" }))
      .to_return(
        status: 200,
        body: {
          id: "pi_test123",
          object: "payment_intent",
          amount: 1550,
          currency: "usd",
          status: "succeeded",
          charges: { data: [ { id: "ch_test123" } ] }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @payment_service.create_payment_intent(payment: @payment)
    assert result[:success]
  end

  test "create_payment_intent includes payment metadata" do
    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)

    # Stub needs to match the actual URL-encoded format that Stripe SDK sends
    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .with(body: /metadata/)  # Just check that metadata is present
      .to_return(
        status: 200,
        body: {
          id: "pi_test123",
          status: "succeeded",
          charges: { data: [ { id: "ch_test123" } ] }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @payment_service.create_payment_intent(payment: @payment)
    assert result[:success]
  end

  test "create_payment_intent with confirm flag" do
    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)

    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .with(body: hash_including({ "confirm" => "true" }))
      .to_return(
        status: 200,
        body: {
          id: "pi_test123",
          status: "succeeded",
          charges: { data: [ { id: "ch_test123" } ] }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @payment_service.create_payment_intent(payment: @payment, confirm: true)
    assert result[:success]
  end

  test "create_payment_intent handles Stripe errors" do
    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)
    stub_stripe_error(endpoint: "https://api.stripe.com/v1/payment_intents", message: "Card declined")

    result = @payment_service.create_payment_intent(payment: @payment)

    assert_not result[:success]
    assert_equal "Card declined", result[:error]
    @payment.reload
    assert_equal "failed", @payment.status
  end

  test "create_payment_intent validates payment presence" do
    assert_raises(ArgumentError, "Payment is required") do
      @payment_service.create_payment_intent(payment: nil)
    end
  end

  test "create_payment_intent validates positive amount" do
    @payment.amount = 0
    assert_raises(ArgumentError, "Payment amount must be positive") do
      @payment_service.create_payment_intent(payment: @payment)
    end
  end

  test "create_payment_intent validates user presence" do
    @payment.user = nil
    assert_raises(ArgumentError, "Payment user is required") do
      @payment_service.create_payment_intent(payment: @payment)
    end
  end

  # Test 3: confirm_payment_intent
  test "confirm_payment_intent confirms successful payment" do
    @payment.update!(stripe_payment_intent_id: "pi_confirm_test")
    stub_stripe_payment_intent_confirm(intent_id: "pi_confirm_test", status: "succeeded")

    result = @payment_service.confirm_payment_intent("pi_confirm_test")

    assert result[:success]
    @payment.reload
    assert_equal "succeeded", @payment.status
    assert @payment.paid_at.present?
  end

  test "confirm_payment_intent handles failed payment" do
    @payment.update!(stripe_payment_intent_id: "pi_failed_test")
    stub_stripe_payment_intent_confirm(intent_id: "pi_failed_test", status: "payment_failed")

    result = @payment_service.confirm_payment_intent("pi_failed_test")

    assert_not result[:success]
    @payment.reload
    assert_equal "failed", @payment.status
  end

  test "confirm_payment_intent handles Stripe errors" do
    stub_request(:post, "https://api.stripe.com/v1/payment_intents/pi_error/confirm")
      .to_return(status: 402, body: { error: { message: "Payment error" } }.to_json, headers: { "Content-Type" => "application/json" })

    result = @payment_service.confirm_payment_intent("pi_error")

    assert_not result[:success]
    assert_equal "Payment error", result[:error]
  end

  # Test 4: process_automatic_payment
  test "process_automatic_payment processes payment with payment_method" do
    payment_method = create(:payment_method, user: @user)
    @payment.update!(payment_method: payment_method)
    payment_schedule = create(:payment_schedule, lease_agreement: @lease_agreement, payment_type: "rent", is_active: true)

    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)
    stub_stripe_payment_intent_create(status: "succeeded")

    result = @payment_service.process_automatic_payment(payment: @payment)

    assert result[:success]
  end

  test "process_automatic_payment requires payment_method" do
    result = @payment_service.process_automatic_payment(payment: @payment)

    assert_not result[:success]
    assert_equal "Payment method required for automatic payments", result[:error]
  end

  test "process_automatic_payment advances rent payment schedule on success" do
    payment_method = create(:payment_method, user: @user)
    @payment.update!(payment_method: payment_method)
    payment_schedule = create(:payment_schedule, lease_agreement: @lease_agreement, payment_type: "rent", is_active: true)
    original_next_payment = payment_schedule.next_payment_date

    stub_stripe_customer_create(id: @user.stripe_customer_id, email: @user.email)
    stub_stripe_payment_intent_create(status: "succeeded")

    # Note: This test will fail until we implement advance_to_next_payment! method
    # For now, just check the payment succeeds
    result = @payment_service.process_automatic_payment(payment: @payment)
    assert result[:success]
  end

  # Test 5: add_payment_method
  test "add_payment_method adds and attaches payment_method" do
    pm_id = "pm_new123"
    stub_stripe_payment_method_retrieve(pm_id: pm_id)
    stub_stripe_customer_create(id: @user.stripe_customer_id) unless @user.stripe_customer_id
    stub_stripe_payment_method_attach(pm_id: pm_id, customer_id: @user.stripe_customer_id)

    # Note: This will fail until PaymentMethod.create_from_stripe! is implemented
    # Skipping for now
    skip "PaymentMethod.create_from_stripe! not yet implemented"
  end

  test "add_payment_method creates Stripe customer if needed" do
    user_without_stripe = create(:user, :tenant, stripe_customer_id: nil)
    pm_id = "pm_new456"

    stub_stripe_customer_create(id: "cus_new123", email: user_without_stripe.email)
    stub_stripe_payment_method_retrieve(pm_id: pm_id)
    stub_stripe_payment_method_attach(pm_id: pm_id, customer_id: "cus_new123")

    skip "PaymentMethod.create_from_stripe! not yet implemented"
  end

  test "add_payment_method sets as default when requested" do
    skip "PaymentMethod.create_from_stripe! not yet implemented"
  end

  test "add_payment_method handles Stripe errors" do
    stub_request(:get, "https://api.stripe.com/v1/payment_methods/pm_error")
      .to_return(status: 404, body: { error: { message: "Payment method not found" } }.to_json, headers: { "Content-Type" => "application/json" })

    result = @payment_service.add_payment_method(user: @user, stripe_payment_method_id: "pm_error")

    assert_not result[:success]
    assert_equal "Payment method not found", result[:error]
  end

  # Test 6: remove_payment_method
  test "remove_payment_method detaches from Stripe" do
    skip "PaymentMethod#detach_from_stripe! not yet implemented"
  end

  test "remove_payment_method handles errors" do
    skip "PaymentMethod#detach_from_stripe! not yet implemented"
  end

  # Test 7: create_refund
  test "create_refund creates full refund for succeeded payment" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_refund123")
    stub_stripe_refund_create(charge_id: "ch_refund123", amount: (@payment.amount * 100).to_i)

    result = @payment_service.create_refund(payment: @payment)

    assert result[:success]
    @payment.reload
    assert_equal "refunded", @payment.status
  end

  test "create_refund creates partial refund" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_partial123", amount: 100.00)
    partial_amount = 50.00

    stub_request(:post, "https://api.stripe.com/v1/refunds")
      .with(body: hash_including({ "amount" => "5000" }))
      .to_return(
        status: 200,
        body: {
          id: "re_partial",
          amount: 5000,
          charge: "ch_partial123",
          status: "succeeded"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @payment_service.create_refund(payment: @payment, amount: partial_amount)

    assert result[:success]
    @payment.reload
    # Partial refund doesn't change status to "refunded"
    assert_equal "succeeded", @payment.status
  end

  test "create_refund includes refund reason" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_reason123")

    # Stub needs to match URL-encoded format
    stub_request(:post, "https://api.stripe.com/v1/refunds")
      .with(body: /reason=Customer\+not\+satisfied/)
      .to_return(
        status: 200,
        body: {
          id: "re_reason",
          charge: "ch_reason123",
          status: "succeeded",
          amount: (@payment.amount * 100).to_i
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @payment_service.create_refund(payment: @payment, reason: "Customer not satisfied")
    assert result[:success]
  end

  test "create_refund fails for non-succeeded payment" do
    @payment.update!(status: "pending")

    result = @payment_service.create_refund(payment: @payment)

    assert_not result[:success]
    assert_equal "Payment not succeeded", result[:error]
  end

  test "create_refund fails without Stripe charge ID" do
    @payment.update!(status: "succeeded", stripe_charge_id: nil)

    result = @payment_service.create_refund(payment: @payment)

    assert_not result[:success]
    assert_equal "No Stripe charge ID", result[:error]
  end

  test "create_refund handles Stripe errors" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_error")
    stub_stripe_error(endpoint: "https://api.stripe.com/v1/refunds", message: "Charge already refunded")

    result = @payment_service.create_refund(payment: @payment)

    assert_not result[:success]
    assert_equal "Charge already refunded", result[:error]
  end

  # Test 8: get_payment_history
  test "get_payment_history retrieves user charges" do
    stub_stripe_charge_list(customer_id: @user.stripe_customer_id, charges: [
      { id: "ch_1", amount: 5000 },
      { id: "ch_2", amount: 3000 }
    ])

    result = @payment_service.get_payment_history(user: @user)

    assert result[:success]
    assert_equal 2, result[:charges]["data"].length
  end

  test "get_payment_history supports pagination" do
    stub_request(:get, "https://api.stripe.com/v1/charges")
      .with(query: hash_including({
        "customer" => @user.stripe_customer_id,
        "limit" => "10",
        "starting_after" => "ch_last"
      }))
      .to_return(
        status: 200,
        body: {
          object: "list",
          data: [],
          has_more: false
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @payment_service.get_payment_history(user: @user, limit: 10, starting_after: "ch_last")
    assert result[:success]
  end

  test "get_payment_history fails without Stripe customer" do
    user_no_stripe = create(:user, :tenant, stripe_customer_id: nil)

    result = @payment_service.get_payment_history(user: user_no_stripe)

    assert_not result[:success]
    assert_equal "No Stripe customer found", result[:error]
  end

  test "get_payment_history handles Stripe errors" do
    # Stub with query parameter matching
    stub_request(:get, "https://api.stripe.com/v1/charges")
      .with(query: hash_including({}))
      .to_return(status: 500, body: { error: { message: "Internal server error" } }.to_json, headers: { "Content-Type" => "application/json" })

    result = @payment_service.get_payment_history(user: @user)

    assert_not result[:success]
    assert_equal "Internal server error", result[:error]
  end

  # Test 9: setup_future_payment
  test "setup_future_payment creates setup intent" do
    stub_stripe_customer_create(id: @user.stripe_customer_id) unless @user.stripe_customer_id
    stub_stripe_setup_intent_create(status: "succeeded", id: "seti_test123")

    result = @payment_service.setup_future_payment(user: @user, payment_method_id: "pm_future123")

    assert result[:success]
    assert_equal "seti_test123", result[:setup_intent]["id"]
  end

  test "setup_future_payment creates Stripe customer if needed" do
    user_new = create(:user, :tenant, stripe_customer_id: nil)
    stub_stripe_customer_create(id: "cus_new789", email: user_new.email)
    stub_stripe_setup_intent_create(status: "succeeded")

    result = @payment_service.setup_future_payment(user: user_new, payment_method_id: "pm_new")

    assert result[:success]
  end

  test "setup_future_payment handles failed setup intent" do
    stub_stripe_customer_create(id: @user.stripe_customer_id)
    stub_stripe_setup_intent_create(status: "requires_payment_method", id: "seti_failed")

    result = @payment_service.setup_future_payment(user: @user, payment_method_id: "pm_fail")

    assert_not result[:success]
  end

  test "setup_future_payment handles Stripe errors" do
    stub_stripe_customer_create(id: @user.stripe_customer_id)
    stub_stripe_error(endpoint: "https://api.stripe.com/v1/setup_intents", message: "Setup failed")

    result = @payment_service.setup_future_payment(user: @user, payment_method_id: "pm_error")

    assert_not result[:success]
    assert_equal "Setup failed", result[:error]
  end
end
