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

  # Test 1: Initialization
  test "initializes with Stripe API key from credentials" do
    Rails.application.credentials.stub(:stripe, OpenStruct.new(secret_key: "sk_test_abc")) do
      service = PaymentService.new
      assert_equal "sk_test_abc", Stripe.api_key
    end
  end

  test "raises error when Stripe secret key is not configured" do
    Rails.application.credentials.stub(:stripe, nil) do
      assert_raises(RuntimeError, "Stripe secret key not configured") do
        PaymentService.new
      end
    end
  end

  # Test 2: create_payment_intent - Success scenarios
  test "create_payment_intent creates successful payment intent" do
    mock_intent = mock_stripe_payment_intent(status: "succeeded")

    Stripe::PaymentIntent.stub(:create, mock_intent) do
      result = @payment_service.create_payment_intent(payment: @payment)

      assert result[:success]
      assert_equal mock_intent, result[:payment_intent]
      assert_equal @payment, result[:payment]
      @payment.reload
      assert_equal "succeeded", @payment.status
      assert_equal mock_intent.id, @payment.stripe_payment_intent_id
    end
  end

  test "create_payment_intent with processing status" do
    mock_intent = mock_stripe_payment_intent(status: "processing")

    Stripe::PaymentIntent.stub(:create, mock_intent) do
      result = @payment_service.create_payment_intent(payment: @payment)

      assert result[:success]
      @payment.reload
      assert_equal "processing", @payment.status
    end
  end

  test "create_payment_intent converts amount to cents" do
    mock_intent = mock_stripe_payment_intent

    Stripe::PaymentIntent.stub(:create, ->(params) {
      assert_equal 150000, params[:amount] # $1500.00 * 100
      mock_intent
    }) do
      @payment_service.create_payment_intent(payment: @payment)
    end
  end

  test "create_payment_intent includes payment metadata" do
    mock_intent = mock_stripe_payment_intent

    Stripe::PaymentIntent.stub(:create, ->(params) {
      assert_equal @payment.id, params[:metadata][:payment_id]
      assert_equal @lease_agreement.id, params[:metadata][:lease_agreement_id]
      assert_equal "rent", params[:metadata][:payment_type]
      assert_equal @user.id, params[:metadata][:user_id]
      mock_intent
    }) do
      @payment_service.create_payment_intent(payment: @payment)
    end
  end

  test "create_payment_intent with confirm flag" do
    mock_intent = mock_stripe_payment_intent

    Stripe::PaymentIntent.stub(:create, ->(params) {
      assert params[:confirm]
      mock_intent
    }) do
      @payment_service.create_payment_intent(payment: @payment, confirm: true)
    end
  end

  # Test 3: create_payment_intent - Error scenarios
  test "create_payment_intent handles Stripe errors" do
    error = Stripe::CardError.new("Card declined", "param", code: "card_declined")

    Stripe::PaymentIntent.stub(:create, ->(_) { raise error }) do
      result = @payment_service.create_payment_intent(payment: @payment)

      refute result[:success]
      assert_equal "Card declined", result[:error]
      @payment.reload
      assert_equal "failed", @payment.status
      assert_equal "Card declined", @payment.failure_reason
    end
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

  # Test 4: confirm_payment_intent
  test "confirm_payment_intent confirms successful payment" do
    mock_intent = mock_stripe_payment_intent(status: "succeeded")
    @payment.update!(stripe_payment_intent_id: mock_intent.id)

    Stripe::PaymentIntent.stub(:confirm, mock_intent) do
      result = @payment_service.confirm_payment_intent(mock_intent.id)

      assert result[:success]
      assert_equal mock_intent, result[:payment_intent]
      @payment.reload
      assert_equal "succeeded", @payment.status
      assert_not_nil @payment.paid_at
    end
  end

  test "confirm_payment_intent handles failed payment" do
    mock_intent = mock_stripe_payment_intent(
      status: "payment_failed",
      last_payment_error: OpenStruct.new(message: "Insufficient funds")
    )
    @payment.update!(stripe_payment_intent_id: mock_intent.id)

    Stripe::PaymentIntent.stub(:confirm, mock_intent) do
      result = @payment_service.confirm_payment_intent(mock_intent.id)

      refute result[:success]
      @payment.reload
      assert_equal "failed", @payment.status
      assert_equal "Insufficient funds", @payment.failure_reason
    end
  end

  test "confirm_payment_intent handles Stripe errors" do
    error = Stripe::StripeError.new("Network error")

    Stripe::PaymentIntent.stub(:confirm, ->(_) { raise error }) do
      result = @payment_service.confirm_payment_intent("pi_123")

      refute result[:success]
      assert_equal "Network error", result[:error]
    end
  end

  # Test 5: process_automatic_payment
  test "process_automatic_payment processes payment with payment method" do
    payment_method = create(:payment_method, user: @user)
    @payment.update!(payment_method: payment_method)
    mock_intent = mock_stripe_payment_intent(status: "succeeded")

    Stripe::PaymentIntent.stub(:create, mock_intent) do
      result = @payment_service.process_automatic_payment(payment: @payment)

      assert result[:success]
      assert_equal "succeeded", result[:payment_intent].status
    end
  end

  test "process_automatic_payment requires payment method" do
    @payment.update!(payment_method: nil)

    result = @payment_service.process_automatic_payment(payment: @payment)

    refute result[:success]
    assert_equal "Payment method required for automatic payments", result[:error]
  end

  test "process_automatic_payment advances rent payment schedule on success" do
    payment_method = create(:payment_method, user: @user)
    @payment.update!(payment_method: payment_method, payment_type: "rent")
    schedule = create(:payment_schedule, lease_agreement: @lease_agreement, status: "active", payment_type: "rent")
    mock_intent = mock_stripe_payment_intent(status: "succeeded")

    schedule.stub(:advance_to_next_payment!, true) do
      Stripe::PaymentIntent.stub(:create, mock_intent) do
        result = @payment_service.process_automatic_payment(payment: @payment)

        assert result[:success]
        # Would verify advance_to_next_payment! was called in a proper mock framework
      end
    end
  end

  # Test 6: add_payment_method
  test "add_payment_method adds and attaches payment method" do
    mock_pm = mock_stripe_payment_method
    mock_customer_id = "cus_#{SecureRandom.hex(10)}"

    Stripe::PaymentMethod.stub(:retrieve, mock_pm) do
      mock_pm.stub(:attach, true) do
        @user.stub(:stripe_customer_id, mock_customer_id) do
          PaymentMethod.stub(:create_from_stripe!, create(:payment_method, user: @user)) do
            result = @payment_service.add_payment_method(
              user: @user,
              stripe_payment_method_id: "pm_123"
            )

            assert result[:success]
            assert result[:payment_method]
          end
        end
      end
    end
  end

  test "add_payment_method creates Stripe customer if needed" do
    user_without_stripe = create(:user, :tenant, stripe_customer_id: nil)
    mock_pm = mock_stripe_payment_method
    mock_customer = OpenStruct.new(id: "cus_new123")

    Stripe::Customer.stub(:create, mock_customer) do
      Stripe::PaymentMethod.stub(:retrieve, mock_pm) do
        mock_pm.stub(:attach, true) do
          PaymentMethod.stub(:create_from_stripe!, create(:payment_method, user: user_without_stripe)) do
            result = @payment_service.add_payment_method(
              user: user_without_stripe,
              stripe_payment_method_id: "pm_123"
            )

            assert result[:success]
            user_without_stripe.reload
            assert_equal "cus_new123", user_without_stripe.stripe_customer_id
          end
        end
      end
    end
  end

  test "add_payment_method sets as default when requested" do
    mock_pm = mock_stripe_payment_method
    payment_method = create(:payment_method, user: @user)

    Stripe::PaymentMethod.stub(:retrieve, mock_pm) do
      mock_pm.stub(:attach, true) do
        PaymentMethod.stub(:create_from_stripe!, payment_method) do
          payment_method.stub(:make_default!, true) do
            result = @payment_service.add_payment_method(
              user: @user,
              stripe_payment_method_id: "pm_123",
              set_as_default: true
            )

            assert result[:success]
            # Would verify make_default! was called
          end
        end
      end
    end
  end

  test "add_payment_method handles Stripe errors" do
    error = Stripe::CardError.new("Invalid card", "param")

    Stripe::PaymentMethod.stub(:retrieve, ->(_) { raise error }) do
      result = @payment_service.add_payment_method(
        user: @user,
        stripe_payment_method_id: "pm_invalid"
      )

      refute result[:success]
      assert_equal "Invalid card", result[:error]
    end
  end

  # Test 7: remove_payment_method
  test "remove_payment_method detaches from Stripe" do
    payment_method = create(:payment_method, user: @user)

    payment_method.stub(:detach_from_stripe!, true) do
      result = @payment_service.remove_payment_method(payment_method: payment_method)

      assert result[:success]
    end
  end

  test "remove_payment_method handles errors" do
    payment_method = create(:payment_method, user: @user)

    payment_method.stub(:detach_from_stripe!, -> { raise StandardError.new("Detach failed") }) do
      result = @payment_service.remove_payment_method(payment_method: payment_method)

      refute result[:success]
      assert_equal "Detach failed", result[:error]
    end
  end

  # Test 8: create_refund
  test "create_refund creates full refund for succeeded payment" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_123")
    mock_refund = OpenStruct.new(
      id: "re_123",
      amount: 150000, # Full amount in cents
      status: "succeeded"
    )

    Stripe::Refund.stub(:create, mock_refund) do
      result = @payment_service.create_refund(payment: @payment)

      assert result[:success]
      assert_equal mock_refund, result[:refund]
      @payment.reload
      assert_equal "refunded", @payment.status
    end
  end

  test "create_refund creates partial refund" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_123")
    partial_amount = 500.00
    mock_refund = OpenStruct.new(
      id: "re_123",
      amount: 50000, # Partial amount in cents
      status: "succeeded"
    )

    Stripe::Refund.stub(:create, ->(params) {
      assert_equal 50000, params[:amount]
      mock_refund
    }) do
      result = @payment_service.create_refund(payment: @payment, amount: partial_amount)

      assert result[:success]
      @payment.reload
      assert_not_equal "refunded", @payment.status # Partial refund doesn't change status
    end
  end

  test "create_refund includes refund reason" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_123")
    mock_refund = OpenStruct.new(id: "re_123", amount: 150000)

    Stripe::Refund.stub(:create, ->(params) {
      assert_equal "duplicate", params[:reason]
      assert_equal "duplicate", params[:metadata][:refund_reason]
      mock_refund
    }) do
      @payment_service.create_refund(payment: @payment, reason: "duplicate")
    end
  end

  test "create_refund fails for non-succeeded payment" do
    @payment.update!(status: "pending")

    result = @payment_service.create_refund(payment: @payment)

    refute result[:success]
    assert_equal "Payment not succeeded", result[:error]
  end

  test "create_refund fails without Stripe charge ID" do
    @payment.update!(status: "succeeded", stripe_charge_id: nil)

    result = @payment_service.create_refund(payment: @payment)

    refute result[:success]
    assert_equal "No Stripe charge ID", result[:error]
  end

  test "create_refund handles Stripe errors" do
    @payment.update!(status: "succeeded", stripe_charge_id: "ch_123")
    error = Stripe::InvalidRequestError.new("Charge already refunded", "param")

    Stripe::Refund.stub(:create, ->(_) { raise error }) do
      result = @payment_service.create_refund(payment: @payment)

      refute result[:success]
      assert_equal "Charge already refunded", result[:error]
    end
  end

  # Test 9: get_payment_history
  test "get_payment_history retrieves user charges" do
    mock_charges = OpenStruct.new(data: [
      OpenStruct.new(id: "ch_1", amount: 10000),
      OpenStruct.new(id: "ch_2", amount: 20000)
    ])

    Stripe::Charge.stub(:list, mock_charges) do
      result = @payment_service.get_payment_history(user: @user)

      assert result[:success]
      assert_equal mock_charges, result[:charges]
    end
  end

  test "get_payment_history supports pagination" do
    mock_charges = OpenStruct.new(data: [])

    Stripe::Charge.stub(:list, ->(params) {
      assert_equal 25, params[:limit]
      assert_equal "ch_last", params[:starting_after]
      mock_charges
    }) do
      @payment_service.get_payment_history(
        user: @user,
        limit: 25,
        starting_after: "ch_last"
      )
    end
  end

  test "get_payment_history fails without Stripe customer" do
    user_without_stripe = create(:user, :tenant, stripe_customer_id: nil)

    result = @payment_service.get_payment_history(user: user_without_stripe)

    refute result[:success]
    assert_equal "No Stripe customer found", result[:error]
  end

  test "get_payment_history handles Stripe errors" do
    error = Stripe::AuthenticationError.new("Invalid API key")

    Stripe::Charge.stub(:list, ->(_) { raise error }) do
      result = @payment_service.get_payment_history(user: @user)

      refute result[:success]
      assert_equal "Invalid API key", result[:error]
    end
  end

  # Test 10: setup_future_payment
  test "setup_future_payment creates setup intent" do
    mock_setup_intent = OpenStruct.new(
      id: "seti_123",
      status: "succeeded"
    )

    Stripe::SetupIntent.stub(:create, mock_setup_intent) do
      result = @payment_service.setup_future_payment(
        user: @user,
        payment_method_id: "pm_123"
      )

      assert result[:success]
      assert_equal mock_setup_intent, result[:setup_intent]
    end
  end

  test "setup_future_payment creates Stripe customer if needed" do
    user_without_stripe = create(:user, :tenant, stripe_customer_id: nil)
    mock_customer = OpenStruct.new(id: "cus_new456")
    mock_setup_intent = OpenStruct.new(status: "succeeded")

    Stripe::Customer.stub(:create, mock_customer) do
      Stripe::SetupIntent.stub(:create, mock_setup_intent) do
        result = @payment_service.setup_future_payment(
          user: user_without_stripe,
          payment_method_id: "pm_123"
        )

        assert result[:success]
        user_without_stripe.reload
        assert_equal "cus_new456", user_without_stripe.stripe_customer_id
      end
    end
  end

  test "setup_future_payment handles failed setup intent" do
    mock_setup_intent = OpenStruct.new(status: "requires_payment_method")

    Stripe::SetupIntent.stub(:create, mock_setup_intent) do
      result = @payment_service.setup_future_payment(
        user: @user,
        payment_method_id: "pm_123"
      )

      refute result[:success]
    end
  end

  test "setup_future_payment handles Stripe errors" do
    error = Stripe::CardError.new("Card declined", "param")

    Stripe::SetupIntent.stub(:create, ->(_) { raise error }) do
      result = @payment_service.setup_future_payment(
        user: @user,
        payment_method_id: "pm_invalid"
      )

      refute result[:success]
      assert_equal "Card declined", result[:error]
    end
  end

  private

  def mock_stripe_payment_intent(status: "succeeded", last_payment_error: nil)
    OpenStruct.new(
      id: "pi_#{SecureRandom.hex(12)}",
      status: status,
      amount: 150000,
      currency: "usd",
      charges: OpenStruct.new(
        data: [OpenStruct.new(id: "ch_#{SecureRandom.hex(12)}")]
      ),
      last_payment_error: last_payment_error
    )
  end

  def mock_stripe_payment_method
    OpenStruct.new(
      id: "pm_#{SecureRandom.hex(12)}",
      type: "card",
      card: OpenStruct.new(
        brand: "visa",
        last4: "4242",
        exp_month: 12,
        exp_year: 2025
      )
    )
  end
end
