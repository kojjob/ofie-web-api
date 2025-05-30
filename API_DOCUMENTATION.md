# Payment System API Documentation

This document provides detailed API specifications for the payment system endpoints.

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication

All endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## Response Format

All responses follow this format:

### Success Response
```json
{
  "status": "success",
  "data": {
    // Response data here
  },
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 50,
      "per_page": 10
    }
  }
}
```

### Error Response
```json
{
  "status": "error",
  "error": "Error message",
  "details": {
    "code": "error_code",
    "field_errors": {
      "field_name": ["error message"]
    }
  }
}
```

## Endpoints

### Payments

#### GET /payments
Retrieve a list of payments for the authenticated user.

**Query Parameters:**
- `status` (string, optional): Filter by payment status (`pending`, `processing`, `succeeded`, `failed`, `canceled`)
- `type` (string, optional): Filter by payment type (`rent`, `security_deposit`, `late_fee`, `utility`, `other`)
- `start_date` (string, optional): Filter payments from this date (YYYY-MM-DD)
- `end_date` (string, optional): Filter payments until this date (YYYY-MM-DD)
- `lease_agreement_id` (string, optional): Filter by lease agreement
- `page` (integer, optional): Page number (default: 1)
- `per_page` (integer, optional): Items per page (default: 10, max: 100)

**Response:**
```json
{
  "status": "success",
  "data": {
    "payments": [
      {
        "id": "uuid",
        "amount": "1200.00",
        "payment_type": "rent",
        "status": "succeeded",
        "description": "Monthly rent payment",
        "due_date": "2024-01-01",
        "paid_at": "2024-01-01T10:00:00Z",
        "created_at": "2024-01-01T09:00:00Z",
        "stripe_payment_intent_id": "pi_xxx",
        "payment_method": {
          "id": "uuid",
          "last_four": "4242",
          "brand": "visa",
          "exp_month": 12,
          "exp_year": 2025
        },
        "lease_agreement": {
          "id": "uuid",
          "property_address": "123 Main St"
        }
      }
    ]
  },
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_count": 25,
      "per_page": 10
    }
  }
}
```

#### GET /payments/:id
Retrieve details of a specific payment.

**Response:**
```json
{
  "status": "success",
  "data": {
    "payment": {
      "id": "uuid",
      "amount": "1200.00",
      "payment_type": "rent",
      "status": "succeeded",
      "description": "Monthly rent payment",
      "due_date": "2024-01-01",
      "paid_at": "2024-01-01T10:00:00Z",
      "created_at": "2024-01-01T09:00:00Z",
      "stripe_payment_intent_id": "pi_xxx",
      "payment_method": {
        "id": "uuid",
        "last_four": "4242",
        "brand": "visa"
      },
      "payer": {
        "id": "uuid",
        "name": "John Doe",
        "email": "john@example.com"
      },
      "lease_agreement": {
        "id": "uuid",
        "property_address": "123 Main St",
        "landlord": {
          "id": "uuid",
          "name": "Jane Smith"
        }
      }
    }
  }
}
```

#### POST /payments
Create a new payment.

**Request Body:**
```json
{
  "payment": {
    "amount": "1200.00",
    "payment_type": "rent",
    "description": "Monthly rent payment",
    "due_date": "2024-01-01",
    "lease_agreement_id": "uuid",
    "payment_method_id": "uuid",
    "auto_confirm": true
  }
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "payment": {
      "id": "uuid",
      "amount": "1200.00",
      "status": "pending",
      "client_secret": "pi_xxx_secret_xxx"
    }
  }
}
```

#### PUT /payments/:id/retry
Retry a failed payment.

**Request Body:**
```json
{
  "payment_method_id": "uuid" // optional, use different payment method
}
```

#### DELETE /payments/:id/cancel
Cancel a pending payment.

#### GET /payments/summary
Get payment summary for the authenticated user.

**Query Parameters:**
- `period` (string, optional): Summary period (`month`, `quarter`, `year`) (default: `month`)
- `year` (integer, optional): Year for summary (default: current year)
- `month` (integer, optional): Month for summary (1-12, required if period is `month`)

**Response:**
```json
{
  "status": "success",
  "data": {
    "summary": {
      "total_paid": "3600.00",
      "total_pending": "1200.00",
      "total_failed": "0.00",
      "payment_count": 3,
      "by_type": {
        "rent": "3600.00",
        "utilities": "0.00",
        "late_fees": "0.00"
      },
      "upcoming_payments": [
        {
          "id": "uuid",
          "amount": "1200.00",
          "due_date": "2024-02-01",
          "payment_type": "rent"
        }
      ]
    }
  }
}
```

### Payment Methods

#### GET /payment_methods
Retrieve user's payment methods.

**Response:**
```json
{
  "status": "success",
  "data": {
    "payment_methods": [
      {
        "id": "uuid",
        "stripe_payment_method_id": "pm_xxx",
        "last_four": "4242",
        "brand": "visa",
        "exp_month": 12,
        "exp_year": 2025,
        "is_default": true,
        "is_expired": false,
        "created_at": "2024-01-01T09:00:00Z"
      }
    ]
  }
}
```

#### POST /payment_methods
Add a new payment method.

**Request Body (for Setup Intent):**
```json
{
  "payment_method": {
    "setup_intent": true
  }
}
```

**Request Body (for Existing Stripe Payment Method):**
```json
{
  "payment_method": {
    "stripe_payment_method_id": "pm_xxx"
  }
}
```

**Response (Setup Intent):**
```json
{
  "status": "success",
  "data": {
    "client_secret": "seti_xxx_secret_xxx",
    "setup_intent_id": "seti_xxx"
  }
}
```

#### PUT /payment_methods/:id/set_default
Set a payment method as default.

#### DELETE /payment_methods/:id
Remove a payment method.

#### POST /payment_methods/setup_intent_success
Notify backend of successful setup intent.

**Request Body:**
```json
{
  "setup_intent_id": "seti_xxx"
}
```

#### GET /payment_methods/:id/validate
Validate a payment method.

**Response:**
```json
{
  "status": "success",
  "data": {
    "is_valid": true,
    "is_expired": false,
    "expires_soon": false,
    "expiry_date": "2025-12-31"
  }
}
```

### Payment Schedules

#### GET /payment_schedules
Retrieve payment schedules.

**Query Parameters:**
- `active` (boolean, optional): Filter by active status
- `auto_pay` (boolean, optional): Filter by auto-pay enabled
- `type` (string, optional): Filter by payment type

**Response:**
```json
{
  "status": "success",
  "data": {
    "payment_schedules": [
      {
        "id": "uuid",
        "amount": "1200.00",
        "payment_type": "rent",
        "frequency": "monthly",
        "day_of_month": 1,
        "start_date": "2024-01-01",
        "end_date": "2024-12-31",
        "next_payment_date": "2024-02-01",
        "auto_pay_enabled": true,
        "is_active": true,
        "lease_agreement": {
          "id": "uuid",
          "property_address": "123 Main St"
        },
        "default_payment_method": {
          "id": "uuid",
          "last_four": "4242",
          "brand": "visa"
        }
      }
    ]
  }
}
```

#### POST /payment_schedules
Create a new payment schedule (landlord only).

**Request Body:**
```json
{
  "payment_schedule": {
    "amount": "1200.00",
    "payment_type": "rent",
    "frequency": "monthly",
    "day_of_month": 1,
    "start_date": "2024-01-01",
    "end_date": "2024-12-31",
    "lease_agreement_id": "uuid",
    "description": "Monthly rent payment"
  }
}
```

#### PUT /payment_schedules/:id/toggle_auto_pay
Toggle auto-pay for a schedule.

**Response:**
```json
{
  "status": "success",
  "data": {
    "payment_schedule": {
      "id": "uuid",
      "auto_pay_enabled": true
    }
  }
}
```

#### GET /payment_schedules/upcoming
Get upcoming payment schedules for the user.

**Query Parameters:**
- `days` (integer, optional): Number of days to look ahead (default: 30)

**Response:**
```json
{
  "status": "success",
  "data": {
    "upcoming_schedules": [
      {
        "id": "uuid",
        "amount": "1200.00",
        "payment_type": "rent",
        "due_date": "2024-02-01",
        "days_until_due": 5,
        "auto_pay_enabled": true,
        "has_default_payment_method": true
      }
    ]
  }
}
```

#### POST /payment_schedules/:id/create_payment
Manually create a payment from a schedule (tenant only).

**Request Body:**
```json
{
  "payment_method_id": "uuid", // optional, uses default if not provided
  "due_date": "2024-02-01" // optional, uses next scheduled date if not provided
}
```

### Security Deposits

#### GET /rental_applications/:id/security_deposits
Get security deposits for a rental application.

#### POST /rental_applications/:id/security_deposits
Create a security deposit for a rental application.

**Request Body:**
```json
{
  "security_deposit": {
    "amount": "2400.00",
    "due_date": "2024-01-15",
    "payment_method_id": "uuid"
  }
}
```

### Lease Agreement Payments

#### GET /lease_agreements/:id/payments
Get payments for a specific lease agreement.

#### POST /lease_agreements/:id/payments
Create a payment for a lease agreement.

## Error Codes

| Code | Description |
|------|-------------|
| `unauthorized` | Invalid or missing authentication token |
| `forbidden` | User doesn't have permission for this action |
| `not_found` | Resource not found |
| `validation_error` | Request validation failed |
| `payment_failed` | Payment processing failed |
| `insufficient_funds` | Insufficient funds on payment method |
| `card_declined` | Payment method was declined |
| `expired_card` | Payment method has expired |
| `invalid_payment_method` | Payment method is invalid or unusable |
| `schedule_conflict` | Payment schedule conflicts with existing schedule |
| `lease_not_active` | Lease agreement is not active |
| `auto_pay_requires_default_method` | Auto-pay requires a default payment method |

## Rate Limiting

API requests are rate limited to:
- 100 requests per minute for authenticated users
- 10 requests per minute for unauthenticated requests

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Webhooks

Stripe webhooks are handled at:
```
POST /stripe/webhooks
```

This endpoint processes Stripe events and updates payment statuses automatically. No authentication required (verified via Stripe signature).

## Testing

### Test Environment
Use the test API base URL for development:
```
http://localhost:3000/api/v1
```

### Test Data
Use Stripe test card numbers:
- Success: `4242424242424242`
- Decline: `4000000000000002`
- Insufficient funds: `4000000000009995`

### Sample cURL Commands

```bash
# Get payments
curl -H "Authorization: Bearer YOUR_TOKEN" \
     "http://localhost:3000/api/v1/payments"

# Create payment
curl -X POST \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "payment": {
         "amount": "1200.00",
         "payment_type": "rent",
         "lease_agreement_id": "uuid",
         "payment_method_id": "uuid"
       }
     }' \
     "http://localhost:3000/api/v1/payments"

# Get payment methods
curl -H "Authorization: Bearer YOUR_TOKEN" \
     "http://localhost:3000/api/v1/payment_methods"
```