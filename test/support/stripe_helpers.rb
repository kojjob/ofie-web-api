module StripeHelpers
  # Stub Stripe::PaymentIntent.create
  # Use hash_including to match requests with any parameters
  def stub_stripe_payment_intent_create(status: "succeeded", amount: 100000, id: "pi_test123")
    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .with(body: hash_including({}))
      .to_return(
        status: 200,
        body: {
          id: id,
          object: "payment_intent",
          amount: amount,
          currency: "usd",
          status: status,
          charges: {
            data: [
              { id: "ch_test123" }
            ]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe::PaymentIntent.confirm
  def stub_stripe_payment_intent_confirm(intent_id:, status: "succeeded")
    stub_request(:post, "https://api.stripe.com/v1/payment_intents/#{intent_id}/confirm")
      .to_return(
        status: 200,
        body: {
          id: intent_id,
          object: "payment_intent",
          status: status,
          charges: {
            data: [
              { id: "ch_test123" }
            ]
          },
          last_payment_error: status == "payment_failed" ? { message: "Payment failed" } : nil
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe::Customer.create
  def stub_stripe_customer_create(id: "cus_test123", email: "test@example.com")
    stub_request(:post, "https://api.stripe.com/v1/customers")
      .to_return(
        status: 200,
        body: {
          id: id,
          object: "customer",
          email: email
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe::PaymentMethod.retrieve
  def stub_stripe_payment_method_retrieve(pm_id: "pm_test123")
    stub_request(:get, "https://api.stripe.com/v1/payment_methods/#{pm_id}")
      .to_return(
        status: 200,
        body: {
          id: pm_id,
          object: "payment_method",
          type: "card",
          card: {
            brand: "visa",
            last4: "4242",
            exp_month: 12,
            exp_year: 2025
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe::PaymentMethod.attach
  def stub_stripe_payment_method_attach(pm_id: "pm_test123", customer_id: "cus_test123")
    stub_request(:post, "https://api.stripe.com/v1/payment_methods/#{pm_id}/attach")
      .with(body: hash_including({ "customer" => customer_id }))
      .to_return(
        status: 200,
        body: {
          id: pm_id,
          object: "payment_method",
          customer: customer_id
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe::Refund.create
  # Use hash_including to match requests with any parameters
  def stub_stripe_refund_create(charge_id: "ch_test123", amount: nil, refund_id: "re_test123")
    stub_request(:post, "https://api.stripe.com/v1/refunds")
      .with(body: hash_including({}))
      .to_return(
        status: 200,
        body: {
          id: refund_id,
          object: "refund",
          amount: amount || 100000,
          charge: charge_id,
          status: "succeeded"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe::Charge.list
  # Use hash_including to match requests with any query parameters
  def stub_stripe_charge_list(customer_id: "cus_test123", charges: [])
    stub_request(:get, "https://api.stripe.com/v1/charges")
      .with(query: hash_including({}))
      .to_return(
        status: 200,
        body: {
          object: "list",
          data: charges,
          has_more: false
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe::SetupIntent.create
  def stub_stripe_setup_intent_create(status: "succeeded", id: "seti_test123")
    stub_request(:post, "https://api.stripe.com/v1/setup_intents")
      .to_return(
        status: 200,
        body: {
          id: id,
          object: "setup_intent",
          status: status
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stub Stripe API errors
  def stub_stripe_error(endpoint:, error_type: "card_error", message: "Card declined")
    stub_request(:post, endpoint)
      .to_return(
        status: 402,
        body: {
          error: {
            type: error_type,
            message: message
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
