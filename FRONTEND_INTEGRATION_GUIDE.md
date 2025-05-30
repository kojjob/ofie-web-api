# Frontend Integration Guide for Payment System

This guide provides comprehensive instructions for integrating the frontend with the newly implemented payment system API.

## Table of Contents

1. [API Endpoints Overview](#api-endpoints-overview)
2. [Authentication](#authentication)
3. [Payment Flow Implementation](#payment-flow-implementation)
4. [Stripe Integration](#stripe-integration)
5. [Component Examples](#component-examples)
6. [Error Handling](#error-handling)
7. [Testing](#testing)

## API Endpoints Overview

### Base URL
```
http://localhost:3000/api/v1
```

### Payment Endpoints

#### Payments
- `GET /payments` - List payments with filters
- `GET /payments/:id` - Get payment details
- `POST /payments` - Create a new payment
- `PUT /payments/:id/retry` - Retry a failed payment
- `DELETE /payments/:id/cancel` - Cancel a pending payment
- `GET /payments/summary` - Get payment summary

#### Payment Methods
- `GET /payment_methods` - List user's payment methods
- `GET /payment_methods/:id` - Get payment method details
- `POST /payment_methods` - Add new payment method
- `PUT /payment_methods/:id` - Update payment method
- `DELETE /payment_methods/:id` - Remove payment method
- `PUT /payment_methods/:id/set_default` - Set as default payment method
- `POST /payment_methods/setup_intent_success` - Handle successful setup intent
- `GET /payment_methods/:id/validate` - Validate payment method

#### Payment Schedules
- `GET /payment_schedules` - List payment schedules
- `GET /payment_schedules/:id` - Get schedule details
- `POST /payment_schedules` - Create new schedule (landlord only)
- `PUT /payment_schedules/:id` - Update schedule (landlord only)
- `DELETE /payment_schedules/:id` - Delete schedule (landlord only)
- `PUT /payment_schedules/:id/activate` - Activate schedule
- `PUT /payment_schedules/:id/deactivate` - Deactivate schedule
- `PUT /payment_schedules/:id/toggle_auto_pay` - Toggle auto-pay
- `GET /payment_schedules/upcoming` - Get upcoming schedules
- `POST /payment_schedules/:id/create_payment` - Create payment from schedule

#### Nested Resources
- `GET /lease_agreements/:id/payments` - Payments for a lease
- `POST /lease_agreements/:id/payments` - Create payment for lease
- `GET /rental_applications/:id/security_deposits` - Security deposits for application
- `POST /rental_applications/:id/security_deposits` - Create security deposit

## Authentication

All API requests require authentication. Include the JWT token in the Authorization header:

```javascript
const headers = {
  'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
  'Content-Type': 'application/json'
};
```

## Payment Flow Implementation

### 1. Setting Up Payment Methods

```javascript
// Create Stripe setup intent for adding payment method
const setupPaymentMethod = async () => {
  try {
    const response = await fetch('/api/v1/payment_methods', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        payment_method: {
          setup_intent: true
        }
      })
    });
    
    const data = await response.json();
    return data.client_secret;
  } catch (error) {
    console.error('Error setting up payment method:', error);
  }
};
```

### 2. Creating Payments

```javascript
// Create a payment
const createPayment = async (paymentData) => {
  try {
    const response = await fetch('/api/v1/payments', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        payment: {
          amount: paymentData.amount,
          payment_type: paymentData.type, // 'rent', 'security_deposit', 'late_fee', 'utility', 'other'
          description: paymentData.description,
          lease_agreement_id: paymentData.leaseId,
          payment_method_id: paymentData.paymentMethodId,
          due_date: paymentData.dueDate
        }
      })
    });
    
    const payment = await response.json();
    
    if (payment.client_secret) {
      // Handle Stripe payment confirmation
      return await confirmStripePayment(payment.client_secret);
    }
    
    return payment;
  } catch (error) {
    console.error('Error creating payment:', error);
  }
};
```

### 3. Fetching Payment History

```javascript
// Get payment history with filters
const getPaymentHistory = async (filters = {}) => {
  const queryParams = new URLSearchParams();
  
  if (filters.status) queryParams.append('status', filters.status);
  if (filters.type) queryParams.append('type', filters.type);
  if (filters.startDate) queryParams.append('start_date', filters.startDate);
  if (filters.endDate) queryParams.append('end_date', filters.endDate);
  if (filters.page) queryParams.append('page', filters.page);
  if (filters.perPage) queryParams.append('per_page', filters.perPage);
  
  try {
    const response = await fetch(`/api/v1/payments?${queryParams}`, {
      headers
    });
    
    return await response.json();
  } catch (error) {
    console.error('Error fetching payment history:', error);
  }
};
```

## Stripe Integration

### Frontend Setup

1. Install Stripe.js:
```bash
npm install @stripe/stripe-js
```

2. Initialize Stripe:
```javascript
import { loadStripe } from '@stripe/stripe-js';

const stripePromise = loadStripe('pk_test_your_publishable_key_here');
```

### Payment Method Setup

```javascript
import { loadStripe } from '@stripe/stripe-js';

const AddPaymentMethodComponent = () => {
  const [stripe, setStripe] = useState(null);
  const [elements, setElements] = useState(null);
  const [clientSecret, setClientSecret] = useState('');
  
  useEffect(() => {
    const initializeStripe = async () => {
      const stripeInstance = await loadStripe('pk_test_your_key');
      setStripe(stripeInstance);
      
      // Get setup intent from backend
      const secret = await setupPaymentMethod();
      setClientSecret(secret);
      
      const elementsInstance = stripeInstance.elements({
        clientSecret: secret
      });
      setElements(elementsInstance);
    };
    
    initializeStripe();
  }, []);
  
  const handleSubmit = async (event) => {
    event.preventDefault();
    
    if (!stripe || !elements) return;
    
    const { error, setupIntent } = await stripe.confirmSetup({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}/payment-methods/success`
      }
    });
    
    if (error) {
      console.error('Payment method setup failed:', error);
    } else {
      // Notify backend of successful setup
      await fetch('/api/v1/payment_methods/setup_intent_success', {
        method: 'POST',
        headers,
        body: JSON.stringify({
          setup_intent_id: setupIntent.id
        })
      });
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <PaymentElement />
      <button type="submit" disabled={!stripe}>
        Add Payment Method
      </button>
    </form>
  );
};
```

### Payment Confirmation

```javascript
const confirmStripePayment = async (clientSecret) => {
  const stripe = await stripePromise;
  
  const { error, paymentIntent } = await stripe.confirmPayment({
    clientSecret,
    confirmParams: {
      return_url: `${window.location.origin}/payments/success`
    }
  });
  
  if (error) {
    console.error('Payment confirmation failed:', error);
    return { success: false, error };
  }
  
  return { success: true, paymentIntent };
};
```

## Component Examples

### Payment Dashboard Component

```javascript
const PaymentDashboard = () => {
  const [payments, setPayments] = useState([]);
  const [paymentMethods, setPaymentMethods] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [paymentsData, methodsData] = await Promise.all([
          getPaymentHistory({ page: 1, per_page: 10 }),
          fetch('/api/v1/payment_methods', { headers }).then(r => r.json())
        ]);
        
        setPayments(paymentsData.payments || []);
        setPaymentMethods(methodsData.payment_methods || []);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, []);
  
  if (loading) return <div>Loading...</div>;
  
  return (
    <div className="payment-dashboard">
      <h2>Payment Dashboard</h2>
      
      <section className="payment-methods">
        <h3>Payment Methods</h3>
        {paymentMethods.map(method => (
          <div key={method.id} className="payment-method-card">
            <span>**** **** **** {method.last_four}</span>
            <span>{method.brand}</span>
            {method.is_default && <span className="default-badge">Default</span>}
          </div>
        ))}
      </section>
      
      <section className="recent-payments">
        <h3>Recent Payments</h3>
        {payments.map(payment => (
          <div key={payment.id} className="payment-card">
            <span>${payment.amount}</span>
            <span>{payment.payment_type}</span>
            <span className={`status ${payment.status}`}>{payment.status}</span>
            <span>{new Date(payment.created_at).toLocaleDateString()}</span>
          </div>
        ))}
      </section>
    </div>
  );
};
```

### Payment Schedule Component

```javascript
const PaymentSchedules = () => {
  const [schedules, setSchedules] = useState([]);
  const [userRole, setUserRole] = useState('tenant'); // or 'landlord'
  
  useEffect(() => {
    const fetchSchedules = async () => {
      try {
        const response = await fetch('/api/v1/payment_schedules', { headers });
        const data = await response.json();
        setSchedules(data.payment_schedules || []);
      } catch (error) {
        console.error('Error fetching schedules:', error);
      }
    };
    
    fetchSchedules();
  }, []);
  
  const toggleAutoPayment = async (scheduleId, currentStatus) => {
    try {
      await fetch(`/api/v1/payment_schedules/${scheduleId}/toggle_auto_pay`, {
        method: 'PUT',
        headers
      });
      
      // Refresh schedules
      setSchedules(schedules.map(schedule => 
        schedule.id === scheduleId 
          ? { ...schedule, auto_pay_enabled: !currentStatus }
          : schedule
      ));
    } catch (error) {
      console.error('Error toggling auto payment:', error);
    }
  };
  
  return (
    <div className="payment-schedules">
      <h2>Payment Schedules</h2>
      
      {schedules.map(schedule => (
        <div key={schedule.id} className="schedule-card">
          <h4>{schedule.payment_type} - ${schedule.amount}</h4>
          <p>Due: {schedule.frequency} on day {schedule.day_of_month}</p>
          <p>Next payment: {new Date(schedule.next_payment_date).toLocaleDateString()}</p>
          
          <div className="schedule-controls">
            <label>
              <input
                type="checkbox"
                checked={schedule.auto_pay_enabled}
                onChange={() => toggleAutoPayment(schedule.id, schedule.auto_pay_enabled)}
              />
              Auto-pay enabled
            </label>
            
            {userRole === 'landlord' && (
              <button onClick={() => editSchedule(schedule.id)}>
                Edit Schedule
              </button>
            )}
          </div>
        </div>
      ))}
    </div>
  );
};
```

## Error Handling

### API Error Response Format

```javascript
{
  "error": "Payment failed",
  "details": {
    "code": "card_declined",
    "message": "Your card was declined."
  }
}
```

### Error Handling Utility

```javascript
const handleApiError = (error, response) => {
  if (response?.status === 401) {
    // Redirect to login
    window.location.href = '/login';
    return;
  }
  
  if (response?.status === 403) {
    alert('You do not have permission to perform this action.');
    return;
  }
  
  if (response?.status === 422) {
    // Validation errors
    const errorData = response.data;
    console.error('Validation errors:', errorData.details);
    return;
  }
  
  // Generic error handling
  console.error('API Error:', error);
  alert('An unexpected error occurred. Please try again.');
};
```

## Testing

### Test Payment Data

For testing with Stripe, use these test card numbers:

- **Successful payment**: `4242424242424242`
- **Declined payment**: `4000000000000002`
- **Insufficient funds**: `4000000000009995`
- **Expired card**: `4000000000000069`

### Environment Variables

Make sure to set up environment variables for different environments:

```javascript
// .env.development
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_...
REACT_APP_API_BASE_URL=http://localhost:3000/api/v1

// .env.production
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_live_...
REACT_APP_API_BASE_URL=https://your-api-domain.com/api/v1
```

## Security Considerations

1. **Never store sensitive payment data** in localStorage or sessionStorage
2. **Always use HTTPS** in production
3. **Validate all inputs** on both frontend and backend
4. **Handle PCI compliance** through Stripe's secure elements
5. **Implement proper error logging** without exposing sensitive information

## Next Steps

1. Set up your Stripe account and get API keys
2. Configure environment variables
3. Implement the payment components in your frontend
4. Test the integration thoroughly
5. Set up monitoring and error tracking
6. Deploy to staging environment for testing

For any questions or issues, refer to the main `PAYMENT_SYSTEM_README.md` file or contact the development team.