# TODO - OFIE Web API Development Roadmap

## Project Status
- **Rails Version**: 8.0.2
- **Ruby Version**: 3.3.0
- **Database**: PostgreSQL 15+
- **Current State**: Development ready, needs production hardening
- **Test Coverage**: ~16% (20 test files for 121+ Ruby files)
- **Last Updated**: 2025-09-19

## Priority Levels
- 🔴 **CRITICAL** - Blocking production deployment
- 🟠 **HIGH** - Required before launch
- 🟡 **MEDIUM** - Important but not blocking
- 🟢 **LOW** - Nice to have improvements

---

## 🔴 CRITICAL - Immediate Actions (Week 1)

### 1. Environment Configuration
- [ ] Create `.env` file from `.env.example`
- [ ] Configure database credentials
- [ ] Set JWT_SECRET_KEY
- [ ] Configure Stripe keys (test keys for now)
- [ ] Set Rails master key

### 2. Test Coverage Expansion
**Target: 80% coverage minimum**

#### Missing Test Files (Priority Order):
- [ ] `spec/services/properties/create_service_spec.rb`
- [ ] `spec/services/properties/search_service_spec.rb`
- [ ] `spec/services/payments/process_payment_service_spec.rb`
- [ ] `spec/services/users/registration_service_spec.rb`
- [ ] `spec/queries/properties_query_spec.rb`
- [ ] `spec/queries/payments_query_spec.rb`
- [ ] `spec/controllers/api/v1/properties_controller_spec.rb`
- [ ] `spec/controllers/api/v1/auth_controller_spec.rb`
- [ ] `spec/controllers/api/v1/payments_controller_spec.rb`
- [ ] `spec/models/lease_agreement_spec.rb`
- [ ] `spec/models/rental_application_spec.rb`
- [ ] `spec/jobs/process_batch_property_upload_job_spec.rb`

#### Test Implementation Tasks:
- [ ] Configure RSpec (migrate from Minitest)
- [ ] Set up FactoryBot factories for all models
- [ ] Add request specs for all API endpoints
- [ ] Add integration tests for critical user flows
- [ ] Configure SimpleCov for coverage reporting

### 3. Security Fixes
- [ ] Review JWT implementation (consider devise-jwt)
- [ ] Fix CSRF protection for web requests
- [ ] Add API versioning headers
- [ ] Implement proper session/token separation
- [ ] Add input validation for all endpoints
- [ ] Configure Content Security Policy
- [ ] Review and fix any SQL injection risks

---

## 🟠 HIGH PRIORITY - Pre-Production (Week 2-3)

### 4. Database Optimization
- [ ] Add missing indexes:
  ```ruby
  # Add to migration
  add_index :properties, :user_id
  add_index :properties, [:latitude, :longitude]
  add_index :lease_agreements, [:property_id, :user_id]
  add_index :payments, :lease_agreement_id
  add_index :maintenance_requests, :property_id
  ```
- [ ] Configure Bullet gem for N+1 detection
- [ ] Optimize slow queries (use `rails db:analyze`)
- [ ] Add database connection pooling configuration
- [ ] Implement query result caching

### 5. API Documentation
- [ ] Configure rswag for API documentation
- [ ] Document all endpoints with request/response examples
- [ ] Add authentication documentation
- [ ] Create Postman collection
- [ ] Add API usage examples
- [ ] Document error codes and responses

### 6. Background Jobs Setup
- [ ] Configure Solid Queue workers
- [ ] Add job error handling and retry logic
- [ ] Implement job monitoring
- [ ] Set up job scheduling for recurring tasks
- [ ] Add dead letter queue handling

---

## 🟡 MEDIUM PRIORITY - Feature Completion (Week 4-5)

### 7. Payment System Completion
- [ ] Implement Stripe webhook handler
- [ ] Add payment failure recovery flow
- [ ] Create subscription management
- [ ] Add invoice generation
- [ ] Implement refund processing
- [ ] Add payment method management
- [ ] Create payment reports

### 8. File Storage Configuration
- [ ] Configure AWS S3 for production
- [ ] Add image resizing and optimization
- [ ] Implement file type validation
- [ ] Add virus scanning (ClamAV)
- [ ] Set up CDN for assets
- [ ] Add direct upload support

### 9. Email System Setup
- [ ] Configure SendGrid or AWS SES
- [ ] Test all email templates
- [ ] Add email preview in development
- [ ] Implement email tracking
- [ ] Add unsubscribe functionality
- [ ] Queue emails with Solid Queue

### 10. Search & Filtering
- [ ] Optimize PostgreSQL full-text search
- [ ] Add search filters for properties
- [ ] Implement location-based search
- [ ] Add saved searches feature
- [ ] Create search analytics

---

## 🟢 NICE TO HAVE - Post-Launch Improvements

### 11. Monitoring & Analytics
- [ ] Configure Sentry error tracking
- [ ] Add New Relic or Datadog APM
- [ ] Implement custom metrics
- [ ] Add user behavior analytics
- [ ] Create admin dashboard
- [ ] Set up uptime monitoring

### 12. Performance Optimization
- [ ] Add Redis caching layer
- [ ] Implement fragment caching
- [ ] Add API response caching
- [ ] Optimize image delivery
- [ ] Add lazy loading
- [ ] Implement pagination everywhere

### 13. Advanced Features
- [ ] Add GraphQL API
- [ ] Implement WebSocket real-time updates
- [ ] Add push notifications
- [ ] Create mobile API endpoints
- [ ] Add multi-language support
- [ ] Implement A/B testing framework

### 14. DevOps Improvements
- [ ] Set up CI/CD pipeline
- [ ] Add automated deployment
- [ ] Configure staging environment
- [ ] Implement blue-green deployment
- [ ] Add database backup automation
- [ ] Set up log aggregation

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] All critical tasks completed
- [ ] Test coverage > 80%
- [ ] Security audit passed
- [ ] Performance testing completed
- [ ] Documentation updated

### Configuration
- [ ] Production environment variables set
- [ ] Rails credentials configured
- [ ] Database migrations ready
- [ ] SSL certificates configured
- [ ] Domain DNS configured

### Deployment Steps
- [ ] Deploy with Kamal or Fly.io
- [ ] Run database migrations
- [ ] Verify health checks
- [ ] Test critical paths
- [ ] Monitor error rates

### Post-Deployment
- [ ] Create admin accounts
- [ ] Seed initial data
- [ ] Configure backups
- [ ] Set up monitoring alerts
- [ ] Document deployment process

---

## 🐛 Known Issues

1. **CSRF Protection**: Currently disabled, needs proper configuration
2. **Test Coverage**: Very low, needs immediate attention
3. **API Versioning**: Headers not properly implemented
4. **N+1 Queries**: Bullet gem installed but not configured
5. **Email Delivery**: Not configured for production

---

## 📚 Technical Debt

1. **Testing Framework**: Consider migrating from Minitest to RSpec
2. **Authentication**: Review custom JWT implementation
3. **Service Objects**: Add consistent error handling
4. **Query Objects**: Add more complex query builders
5. **API Responses**: Standardize response format

---

## 🎯 Quick Wins

1. Add `.env` file (5 minutes)
2. Run RuboCop auto-fix (10 minutes)
3. Configure Bullet gem (15 minutes)
4. Add basic API documentation (1 hour)
5. Write critical path tests (2-3 hours)

---

## 📝 Notes

- Focus on test coverage first - it's critically low
- Security review is essential before production
- Payment system needs thorough testing
- Consider hiring security consultant for review
- Load testing recommended before launch

---

## 🚀 Recommended Workflow

1. **Week 1**: Complete all CRITICAL items
2. **Week 2-3**: Complete HIGH PRIORITY items
3. **Week 4-5**: Complete MEDIUM PRIORITY items
4. **Week 6**: Testing, security review, and deployment prep
5. **Post-Launch**: Iterate on NICE TO HAVE items

---

## 📊 Progress Tracking

| Category | Total Tasks | Completed | Percentage |
|----------|------------|-----------|------------|
| Critical | 15 | 0 | 0% |
| High | 18 | 0 | 0% |
| Medium | 25 | 0 | 0% |
| Nice to Have | 20 | 0 | 0% |
| **Total** | **78** | **0** | **0%** |

---

*Last reviewed: 2025-09-19*
*Next review: [Add date after first sprint]*