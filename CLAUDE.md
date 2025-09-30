# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Running the Application
```bash
# Start the full development environment with live reloading
bin/dev

# Or start components individually:
rails server                    # Start Rails server on port 3000
rails solid_queue:start         # Start background job processor (Solid Queue)

# Check application health
curl http://localhost:3000/health
```

### Testing
```bash
# Run all tests
rails test

# Run specific test file
rails test test/services/properties/create_service_test.rb

# Run tests with coverage report
COVERAGE=true rails test

# Run specific test method
rails test test/models/user_test.rb -n test_valid_user_creation
```

### Code Quality & Linting
```bash
# Ruby linting with RuboCop
bundle exec rubocop
bundle exec rubocop -A          # Auto-fix violations

# JavaScript linting
npm run lint
npm run lint:fix                # Auto-fix violations

# Security scanning
bundle exec brakeman            # Security vulnerability scan
bundle audit                    # Check for vulnerable dependencies

# Run all quality checks
rake quality                    # If defined in lib/tasks
```

### Database Management
```bash
# Setup database from scratch
rails db:create db:migrate db:seed

# Reset database (drop, create, migrate, seed)
rails db:reset

# Run pending migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Check migration status
rails db:migrate:status
```

### Background Jobs (Solid Queue)
```bash
# Check Solid Queue status
rails solid_queue:status

# Clear stuck jobs
rails solid_queue:clear

# Start worker
rails solid_queue:start
```

## Architecture Overview

### Service Object Pattern
The application uses service objects (in `app/services/`) for complex business logic. All services inherit from `ApplicationService` which provides:
- `self.call(...)` class method for instantiation and execution
- `success(data)` and `failure(errors, data)` methods returning `ServiceResult` objects
- `with_transaction` for database transaction management
- Consistent error handling and logging

Example usage:
```ruby
result = Properties::CreateService.call(user: current_user, params: property_params)
if result.success?
  property = result.property
else
  errors = result.errors
end
```

### Query Object Pattern
Query objects (in `app/queries/`) encapsulate complex database queries. They inherit from `ApplicationQuery` providing:
- Chainable query methods
- Common helpers like `paginate`, `order_by`, `includes`
- `apply_filters` for dynamic filtering

### API Architecture
- **Versioned API**: `/api/v1/` namespace for all API endpoints
- **JWT Authentication**: Token-based auth with refresh tokens
- **RESTful Resources**: Nested resources for related entities
- **Service Integration**: Stripe for payments, OAuth for social login

### Rails 8 Features
- **Solid Stack**: Database-backed caching (Solid Cache), background jobs (Solid Queue), and WebSockets (Solid Cable)
- **Kamal Deployment**: Ready for deployment without PaaS dependencies
- **Hotwire**: Stimulus.js for JavaScript, Turbo for SPA-like navigation
- **Import Maps**: JavaScript module management without bundling

### Key Models & Relationships
- **User**: Central authentication model with roles (landlord/tenant)
- **Property**: Core entity with amenities, photos, and location data
- **LeaseAgreement**: Connects properties with tenants, manages rental terms
- **Payment**: Handles rent payments with Stripe integration
- **MaintenanceRequest**: Manages property maintenance workflow
- **Conversation/Message**: Real-time messaging between users

### Testing Strategy
- **Minitest**: Rails default test framework with fixtures
- **FactoryBot**: Test data generation
- **VCR/WebMock**: HTTP request stubbing for external services
- **SimpleCov**: Code coverage tracking (minimum 80%)
- **Database Cleaner**: Transaction-based test isolation

### Frontend Architecture
- **Stimulus.js**: Hotwire framework for JavaScript behavior
- **Bootstrap 5**: CSS framework for responsive design
- **Tailwind CSS**: Utility-first CSS (also available)
- **Action Cable**: Real-time WebSocket features

### Environment Configuration
Key environment variables required (see `.env.example`):
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET_KEY`: Token signing secret
- `STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`: Payment processing
- OAuth credentials for Google/Facebook login (optional)
- AWS S3 credentials for file storage (production)