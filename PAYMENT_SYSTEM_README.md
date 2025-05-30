# Payment System Implementation

This document describes the comprehensive payment system implemented for the Ofie rental platform.

## Overview

The payment system handles:
- Rent payments and security deposits
- Recurring payment schedules
- Payment method management (cards and bank accounts)
- Stripe integration for payment processing
- Automated payment notifications and reminders
- Late fee calculations
- Payment history and reporting

## Database Schema

### Core Models

1. **Payment** - Individual payment records
2. **PaymentMethod** - User payment methods (cards/bank accounts)
3. **PaymentSchedule** - Recurring payment configurations
4. **SecurityDeposit** - Security deposit management
5. **RentalApplication** - Rental application workflow
6. **LeaseAgreement** - Lease contract management

### Key Relationships

```
User
├── PaymentMethods (has_many)
├── Payments (has_many)
├── RentalApplications as tenant (has_many)
├── RentalApplications as reviewer (has_many)
├── LeaseAgreements as tenant (has_many)
└── LeaseAgreements as landlord (has_many)

LeaseAgreement
├── Payments (has_many)
├── PaymentSchedules (has_many)
├── SecurityDeposit (has_one)
├── RentalApplication (belongs_to)
├── Property (belongs_to)
├── Tenant (belongs_to User)
└── Landlord (belongs_to User)

Payment
├── LeaseAgreement (belongs_to)
├── User (belongs_to)
└── PaymentMethod (belongs_to)
```

## API Endpoints

### Payments
- `GET /api/v1/payments` - List payments
- `GET /api/v1/payments/:id` - Get payment details
- `POST /api/v1/lease_agreements/:id/payments` - Create payment
- `POST /api/v1/payments/:id/retry` - Retry failed payment
- `POST /api/v1/payments/:id/cancel` - Cancel payment
- `GET /api/v1/payments/summary` - Payment summary

### Payment Methods
- `GET /api/v1/payment_methods` - List payment methods
- `POST /api/v1/payment_methods` - Add payment method
- `POST /api/v1/payment_methods/:id/make_default` - Set as default
- `DELETE /api/v1/payment_methods/:id` - Remove payment method

### Payment Schedules
- `GET /api/v1/payment_schedules` - List schedules
- `POST /api/v1/lease_agreements/:id/payment_schedules` - Create schedule
- `POST /api/v1/payment_schedules/:id/activate` - Activate schedule
- `POST /api/v1/payment_schedules/:id/toggle_auto_pay` - Toggle auto-pay

### Webhooks
- `POST /api/v1/webhooks/stripe` - Stripe webhook handler

## Payment Flow

### 1. Adding Payment Methods

```javascript
// Create setup intent
POST /api/v1/payment_methods
{
  "type": "stripe_setup_intent"
}

// Frontend collects payment method using Stripe Elements
// Confirm setup intent on frontend

// Notify backend of successful setup
POST /api/v1/payment_methods/setup_intent_success
{
  "setup_intent_id": "seti_xxx"
}
```

### 2. Creating Payments

```javascript
// Create payment
POST /api/v1/lease_agreements/123/payments
{
  "payment": {
    "payment_type": "rent",
    "amount": 1500.00,
    "due_date": "2024-01-01",
    "description": "January 2024 rent"
  },
  "payment_method_id": 456,
  "confirm_immediately": true
}
```

### 3. Recurring Payments

```javascript
// Create payment schedule
POST /api/v1/lease_agreements/123/payment_schedules
{
  "payment_schedule": {
    "payment_type": "rent",
    "amount": 1500.00,
    "frequency": "monthly",
    "start_date": "2024-01-01",
    "day_of_month": 1,
    "auto_pay": true
  }
}
```

## Background Jobs

### RecurringPaymentJob
- Runs daily at 6 AM
- Processes due payment schedules
- Creates and processes automatic payments
- Sends payment notifications

### PaymentNotificationJob
- Sends email and in-app notifications
- Handles payment success/failure notifications
- Sends payment reminders and overdue notices

### StripeWebhookJob
- Processes Stripe webhook events
- Updates payment statuses
- Handles payment method changes

## Configuration

### Environment Variables

Add to `config/credentials.yml.enc`:

```yaml
stripe:
  publishable_key: pk_test_xxx
  secret_key: sk_test_xxx
  webhook_secret: whsec_xxx
```

### Cron Jobs

The system uses the `whenever` gem for scheduling:

```ruby
# config/schedule.rb
every 1.day, at: '6:00 am' do
  runner "RecurringPaymentJob.perform_later"
end
```

Deploy cron jobs:
```bash
whenever --update-crontab
```

## Security Features

1. **PCI Compliance**: No card data stored locally
2. **Webhook Verification**: Stripe signature verification
3. **Access Control**: User authorization for all operations
4. **Audit Trail**: Complete payment history tracking
5. **Secure Tokens**: JWT-based authentication

## Testing

### Stripe Test Mode

Use Stripe test cards:
- Success: `4242424242424242`
- Decline: `4000000000000002`
- Insufficient funds: `4000000000009995`

### Test Payment Flow

```bash
# Create test user and lease
rails console
user = User.create!(name: "Test User", email: "test@example.com", password: "password")
lease = LeaseAgreement.create!(...)

# Test payment creation
payment = Payment.create!(
  lease_agreement: lease,
  user: user,
  payment_type: "rent",
  amount: 1500.00,
  due_date: Date.current
)
```

## Monitoring

### Key Metrics
- Payment success rate
- Failed payment reasons
- Late payment frequency
- Auto-pay adoption rate

### Logging
- All payment operations logged
- Stripe webhook events logged
- Failed payment attempts tracked

### Alerts
- High failure rates
- Webhook processing errors
- Overdue payments

## Deployment

### Database Migrations

```bash
rails db:migrate
```

### Background Jobs

Ensure background job processor is running:

```bash
# Using Sidekiq
bundle exec sidekiq

# Or using delayed_job
bin/delayed_job start
```

### Webhook Endpoints

Configure Stripe webhook URL:
- Development: `https://your-ngrok-url.ngrok.io/api/v1/webhooks/stripe`
- Production: `https://your-domain.com/api/v1/webhooks/stripe`

## Troubleshooting

### Common Issues

1. **Payment Failures**
   - Check Stripe dashboard for details
   - Verify payment method validity
   - Check webhook delivery

2. **Webhook Issues**
   - Verify webhook secret configuration
   - Check endpoint accessibility
   - Review webhook logs in Stripe dashboard

3. **Auto-pay Not Working**
   - Verify payment schedule is active
   - Check user has default payment method
   - Review cron job execution

### Debug Commands

```bash
# Check payment status
Payment.find(id).status

# Retry failed payment
PaymentService.new.retry_payment(payment)

# Check webhook events
Stripe::Event.list(limit: 10)

# Test webhook processing
StripeWebhookJob.perform_now(webhook_data)
```

## Future Enhancements

1. **ACH Payments**: Direct bank transfers
2. **Payment Plans**: Installment payments
3. **Multi-currency**: International payments
4. **Mobile Payments**: Apple Pay, Google Pay
5. **Cryptocurrency**: Bitcoin, Ethereum support
6. **Analytics Dashboard**: Payment insights
7. **Automated Collections**: Dunning management

## Support

For payment system issues:
1. Check application logs
2. Review Stripe dashboard
3. Verify webhook delivery
4. Contact development team

---

*Last updated: December 2024*