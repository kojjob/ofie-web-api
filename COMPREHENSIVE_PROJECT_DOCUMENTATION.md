# Ofie Rental Platform - Comprehensive Documentation

A complete Ruby on Rails rental property management platform with integrated payment processing, messaging, and property management features.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture & Design](#architecture--design)
4. [Database Schema](#database-schema)
5. [API Documentation](#api-documentation)
6. [Payment System](#payment-system)
7. [Authentication & Authorization](#authentication--authorization)
8. [Property Management](#property-management)
9. [Messaging System](#messaging-system)
10. [Maintenance Requests](#maintenance-requests)
11. [Frontend Integration](#frontend-integration)
12. [Deployment & Infrastructure](#deployment--infrastructure)
13. [Development Setup](#development-setup)
14. [Testing](#testing)
15. [Security](#security)
16. [Performance](#performance)
17. [Monitoring & Logging](#monitoring--logging)

## Project Overview

Ofie is a comprehensive rental property management platform that connects landlords and tenants through a modern web application. The platform facilitates property listings, rental applications, lease management, payment processing, and ongoing communication between parties.

### Key Features

- **Property Management**: Create, edit, and manage property listings with photos and detailed information
- **User Management**: Separate roles for landlords and tenants with role-based permissions
- **Rental Applications**: Complete application workflow from submission to approval
- **Lease Management**: Digital lease agreements with electronic signatures
- **Payment Processing**: Integrated Stripe payment system for rent, deposits, and fees
- **Messaging System**: Real-time communication between landlords and tenants
- **Maintenance Requests**: Submit and track property maintenance issues
- **Reviews & Ratings**: Property and user review system
- **Notifications**: Email and in-app notifications for important events

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.0.2
- **Language**: Ruby 3.x
- **Database**: PostgreSQL with UUID primary keys
- **Authentication**: JWT tokens with bcrypt password hashing
- **Payment Processing**: Stripe API integration
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Real-time**: Solid Cable (Action Cable)
- **File Storage**: Active Storage
- **Email**: Action Mailer

### Frontend
- **Framework**: Hotwire (Turbo + Stimulus)
- **Styling**: TailwindCSS
- **Asset Pipeline**: Rails 8 asset pipeline
- **JavaScript**: Stimulus controllers

### Infrastructure
- **Containerization**: Docker
- **Deployment**: Kamal
- **Web Server**: Puma
- **Reverse Proxy**: Thruster

### Development Tools
- **Code Quality**: RuboCop
- **Security**: Brakeman
- **Testing**: Rails built-in testing framework
- **API Documentation**: Custom documentation

## Architecture & Design

### Design Principles

1. **Domain-Driven Design**: Clear separation of business domains
2. **RESTful API Design**: Standard HTTP methods and status codes
3. **Service-Oriented Architecture**: Business logic encapsulated in service objects
4. **Event-Driven Architecture**: Background jobs for async processing
5. **Security First**: Authentication, authorization, and data validation

### Application Structure

```
app/
├── controllers/          # HTTP request handling
│   ├── api/v1/          # API endpoints
│   └── concerns/        # Shared controller logic
├── models/              # Domain models and business logic
├── services/            # Business logic services
├── jobs/                # Background job processing
├── mailers/             # Email templates and logic
├── serializers/         # JSON response formatting
├── policies/            # Authorization policies
└── views/               # HTML templates
```

### Key Design Patterns

- **Service Objects**: Complex business logic (PaymentService, MessagingService)
- **Policy Objects**: Authorization logic (Pundit policies)
- **Job Objects**: Asynchronous processing (PaymentNotificationJob)
- **Serializers**: API response formatting
- **Concerns**: Shared functionality across models/controllers

## Database Schema

### Core Entities

#### Users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  password_digest VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  role VARCHAR NOT NULL, -- 'tenant' or 'landlord'
  phone VARCHAR,
  bio TEXT,
  stripe_customer_id VARCHAR UNIQUE,
  email_verified_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### Properties
```sql
CREATE TABLE properties (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title VARCHAR NOT NULL,
  description TEXT,
  address VARCHAR NOT NULL,
  city VARCHAR NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  property_type VARCHAR, -- 'apartment', 'house', etc.
  availability_status INTEGER, -- enum
  bedrooms INTEGER,
  bathrooms DECIMAL(3,1),
  square_feet INTEGER,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### Lease Agreements
```sql
CREATE TABLE lease_agreements (
  id UUID PRIMARY KEY,
  rental_application_id UUID REFERENCES rental_applications(id),
  landlord_id UUID REFERENCES users(id),
  tenant_id UUID REFERENCES users(id),
  property_id UUID REFERENCES properties(id),
  lease_start_date DATE NOT NULL,
  lease_end_date DATE NOT NULL,
  monthly_rent DECIMAL(10,2) NOT NULL,
  security_deposit_amount DECIMAL(10,2),
  status VARCHAR DEFAULT 'draft',
  lease_number VARCHAR UNIQUE,
  signed_by_tenant_at TIMESTAMP,
  signed_by_landlord_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### Payments
```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY,
  lease_agreement_id UUID REFERENCES lease_agreements(id),
  user_id UUID REFERENCES users(id),
  payment_method_id UUID REFERENCES payment_methods(id),
  amount DECIMAL(10,2) NOT NULL,
  payment_type VARCHAR NOT NULL, -- 'rent', 'security_deposit', etc.
  status VARCHAR NOT NULL, -- 'pending', 'succeeded', 'failed', etc.
  payment_number VARCHAR UNIQUE,
  description TEXT,
  due_date DATE,
  paid_at TIMESTAMP,
  stripe_payment_intent_id VARCHAR,
  stripe_charge_id VARCHAR,
  failure_reason TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Relationships

- **User** has many Properties, Payments, PaymentMethods, Conversations, Messages
- **Property** belongs to User, has many LeaseAgreements, PropertyReviews, MaintenanceRequests
- **LeaseAgreement** belongs to Property, Landlord (User), Tenant (User), has many Payments
- **Payment** belongs to LeaseAgreement, User, PaymentMethod
- **Conversation** belongs to Landlord (User), Tenant (User), Property

## API Documentation

### Base URL
```
http://localhost:3000/api/v1
```

### Authentication
All API endpoints require JWT authentication:
```
Authorization: Bearer <jwt_token>
```

### Response Format

#### Success Response
```json
{
  "status": "success",
  "data": {
    // Response data
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

#### Error Response
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

### Core Endpoints

#### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout
- `GET /auth/me` - Get current user
- `POST /auth/refresh` - Refresh JWT token
- `POST /auth/forgot_password` - Password reset request
- `PATCH /auth/reset_password` - Reset password

#### Properties
- `GET /properties` - List properties with filters
- `GET /properties/:id` - Get property details
- `POST /properties` - Create property (landlord only)
- `PATCH /properties/:id` - Update property (landlord only)
- `DELETE /properties/:id` - Delete property (landlord only)

#### Payments
- `GET /payments` - List user payments
- `GET /payments/:id` - Get payment details
- `POST /lease_agreements/:id/payments` - Create payment
- `POST /payments/:id/retry` - Retry failed payment
- `POST /payments/:id/cancel` - Cancel payment

#### Payment Methods
- `GET /payment_methods` - List payment methods
- `POST /payment_methods` - Add payment method
- `POST /payment_methods/:id/make_default` - Set default
- `DELETE /payment_methods/:id` - Remove payment method

## Payment System

### Overview
The payment system is built on Stripe and handles:
- Rent payments and security deposits
- Recurring payment schedules
- Payment method management
- Automated notifications
- Late fee calculations

### Payment Flow

1. **Setup Payment Method**
   - Create Stripe setup intent
   - Collect payment method via Stripe Elements
   - Store payment method securely

2. **Create Payment**
   - Generate payment record
   - Create Stripe payment intent
   - Process payment
   - Update payment status

3. **Handle Webhooks**
   - Receive Stripe webhook events
   - Update payment status
   - Send notifications

### Payment Types
- `rent` - Monthly rent payments
- `security_deposit` - Security deposits
- `late_fee` - Late payment fees
- `utility` - Utility payments
- `maintenance_fee` - Maintenance costs
- `other` - Other charges

### Payment Statuses
- `pending` - Payment created, not processed
- `processing` - Payment being processed
- `succeeded` - Payment completed successfully
- `failed` - Payment failed
- `canceled` - Payment canceled
- `refunded` - Payment refunded

### Recurring Payments
Payment schedules automate recurring payments:
- Monthly rent payments
- Configurable payment dates
- Auto-pay functionality
- Payment reminders

## Authentication & Authorization

### Authentication
- JWT tokens for API authentication
- bcrypt for password hashing
- OAuth integration (Google, Facebook)
- Email verification
- Password reset functionality

### Authorization
- Role-based access control (landlord/tenant)
- Resource-level permissions
- Policy-based authorization using Pundit

### User Roles

#### Landlord
- Create and manage properties
- Review rental applications
- Create lease agreements
- Manage maintenance requests
- Access payment reports

#### Tenant
- Browse and favorite properties
- Submit rental applications
- Make payments
- Submit maintenance requests
- Communicate with landlords

## Property Management

### Features
- Property listings with photos
- Detailed property information
- Availability status management
- Property search and filtering
- Property favorites
- Property reviews and ratings
- Virtual and in-person viewings

### Property Types
- Apartment
- House
- Condo
- Townhouse
- Studio
- Loft

### Availability Statuses
- Available
- Rented
- Pending
- Maintenance

## Messaging System

### Features
- Real-time messaging between landlords and tenants
- Property-specific conversations
- Message read receipts
- Email notifications for new messages

### Implementation
- Conversation model for message threads
- Message model for individual messages
- Policy-based access control
- Real-time updates via Action Cable

## Maintenance Requests

### Features
- Submit maintenance requests with photos
- Priority levels (low, medium, high, urgent)
- Status tracking
- Cost estimation
- Assignment to maintenance personnel
- Progress updates

### Request Categories
- Plumbing
- Electrical
- HVAC
- Appliances
- General maintenance
- Emergency repairs

### Status Flow
1. Pending - Request submitted
2. Acknowledged - Landlord acknowledged
3. In Progress - Work started
4. Completed - Work finished
5. Closed - Request closed

## Frontend Integration

### Hotwire Integration
- Turbo for page navigation
- Turbo Frames for partial updates
- Turbo Streams for real-time updates
- Stimulus controllers for JavaScript behavior

### TailwindCSS Styling
- Utility-first CSS framework
- Responsive design
- Component-based styling
- Custom design system

### Key Frontend Components
- Property listing cards
- Payment forms with Stripe Elements
- Messaging interface
- Dashboard layouts
- Modal dialogs
- Form validation

## Deployment & Infrastructure

### Docker Configuration
```dockerfile
FROM ruby:3.x
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

### Kamal Deployment
- Zero-downtime deployments
- Docker-based deployment
- SSL certificate management
- Health checks
- Rollback capabilities

### Environment Configuration
- Development: Local PostgreSQL, Redis
- Production: Managed database services
- Staging: Mirror of production

## Development Setup

### Prerequisites
- Ruby 3.x
- PostgreSQL 12+
- Node.js 16+
- Redis (for Action Cable)

### Installation
```bash
# Clone repository
git clone <repository-url>
cd ofie-web-api

# Install dependencies
bundle install
npm install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Start development server
bin/dev
```

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://localhost/ofie_development

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# OAuth
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
FACEBOOK_APP_ID=...
FACEBOOK_APP_SECRET=...

# Email
SMTP_HOST=smtp.gmail.com
SMTP_USERNAME=...
SMTP_PASSWORD=...
```

## Testing

### Test Structure
```
test/
├── controllers/     # Controller tests
├── models/         # Model tests
├── services/       # Service tests
├── jobs/           # Job tests
├── mailers/        # Mailer tests
├── integration/    # Integration tests
└── fixtures/       # Test data
```

### Running Tests
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run with coverage
rails test:coverage
```

### Test Data
- Fixtures for consistent test data
- Factory methods for dynamic data
- Mocked external services (Stripe)

## Security

### Security Measures
- JWT token authentication
- Password hashing with bcrypt
- SQL injection prevention
- XSS protection
- CSRF protection
- Rate limiting
- Input validation
- Secure headers

### Data Protection
- Encrypted sensitive data
- PCI compliance for payments
- GDPR compliance considerations
- Regular security audits

### Security Tools
- Brakeman for static analysis
- Bundle audit for dependency scanning
- Regular security updates

## Performance

### Optimization Strategies
- Database indexing
- Query optimization
- Caching with Solid Cache
- Background job processing
- Asset optimization
- CDN for static assets

### Monitoring
- Application performance monitoring
- Database query analysis
- Error tracking
- Uptime monitoring

## Monitoring & Logging

### Logging
- Structured logging with Rails logger
- Request/response logging
- Error logging with stack traces
- Payment transaction logging
- Security event logging

### Metrics
- Application metrics
- Business metrics (payments, users)
- Performance metrics
- Error rates

### Alerting
- Error rate alerts
- Performance degradation alerts
- Payment failure alerts
- Security incident alerts

---

## Contributing

### Development Workflow
1. Create feature branch
2. Implement changes with tests
3. Run test suite
4. Submit pull request
5. Code review
6. Merge to main

### Code Standards
- Follow Rails conventions
- Use RuboCop for code style
- Write comprehensive tests
- Document public APIs
- Follow security best practices

### Git Workflow
- Feature branches for new development
- Descriptive commit messages
- Squash commits before merging
- Tag releases

---

*This documentation covers the complete Ofie rental platform. For specific implementation details, refer to the source code and inline documentation.*