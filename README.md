# OFIE Web API 🏠

[![Rails Version](https://img.shields.io/badge/Rails-8.0.2-red)](https://rubyonrails.org/)
[![Ruby Version](https://img.shields.io/badge/Ruby-3.3.0-red)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern, comprehensive real estate management platform built with Ruby on Rails 8, designed to streamline property management, tenant-landlord interactions, and rental operations.

## 🚀 Features

### For Landlords
- **Property Management**: List, edit, and manage multiple properties with detailed specifications
- **Tenant Management**: Track tenants, lease agreements, and rental history
- **Financial Dashboard**: Monitor payments, generate reports, and track revenue
- **Maintenance Tracking**: Handle maintenance requests efficiently
- **Document Management**: Store and manage lease agreements, contracts, and other documents
- **Analytics & Insights**: Detailed occupancy rates, revenue trends, and performance metrics

### For Tenants
- **Property Search**: Advanced search with filters for location, price, amenities
- **Online Applications**: Submit rental applications digitally
- **Payment Portal**: Secure online rent payments via Stripe
- **Maintenance Requests**: Submit and track maintenance issues
- **Document Access**: View lease agreements and important documents
- **Communication Hub**: Direct messaging with landlords

### Platform Features
- **Real-time Notifications**: Instant updates on applications, payments, and messages
- **Mobile-Responsive Design**: Optimized for all devices
- **Secure Authentication**: JWT-based authentication with OAuth support
- **Multi-language Support**: Internationalization ready
- **Advanced Search**: Full-text search with PostgreSQL
- **API-First Architecture**: RESTful API for mobile and third-party integrations

## 🛠 Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.0.2
- **Database**: PostgreSQL 15+
- **Caching**: Solid Cache (Rails 8 native)
- **Background Jobs**: Solid Queue / Sidekiq
- **Authentication**: Devise + JWT
- **Authorization**: Pundit
- **File Storage**: Active Storage with S3
- **Payment Processing**: Stripe
- **Search**: PostgreSQL Full-Text Search with pg_trgm

### Frontend
- **JavaScript**: Stimulus.js (Hotwire)
- **CSS Framework**: Bootstrap 5
- **Icons**: Font Awesome
- **Charts**: Chart.js
- **Forms**: Simple Form
- **Real-time**: Action Cable

### Development & Testing
- **Testing**: RSpec, FactoryBot, Faker
- **Code Quality**: RuboCop, Brakeman, Bundler Audit
- **API Documentation**: Swagger/OpenAPI
- **Development Tools**: Letter Opener, Pry, Better Errors

## 📋 Prerequisites

- Ruby 3.3.0
- Rails 8.0.2
- PostgreSQL 15+
- Redis 7+ (optional, for Action Cable)
- Node.js 18+ and Yarn
- ImageMagick (for image processing)

## 🔧 Installation

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/ofie-web-api.git
cd ofie-web-api
```

### 2. Install dependencies
```bash
# Install Ruby dependencies
bundle install

# Install JavaScript dependencies
yarn install
```

### 3. Setup environment variables
```bash
cp .env.example .env
```

Edit `.env` and configure:
```env
# Database
DATABASE_URL=postgresql://username:password@localhost/ofie_development

# JWT Secret
JWT_SECRET_KEY=your-secret-key-here

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# OAuth (optional)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# AWS S3 (for production file storage)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_BUCKET=your-bucket-name

# SendGrid (for production emails)
SENDGRID_API_KEY=your-sendgrid-key
```

### 4. Setup database
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed sample data (optional)
rails db:seed
```

### 5. Setup full-text search
```bash
# Enable pg_trgm extension (included in migrations)
rails db:migrate
```

### 6. Start the application
```bash
# Start Rails server
rails server

# In another terminal, start Solid Queue for background jobs
rails solid_queue:start

# For development with live reloading
bin/dev
```

Visit `http://localhost:3000`

## 🏗 Architecture

### Service Objects Pattern
The application uses service objects for complex business logic:

```ruby
# Example usage
result = Properties::CreateService.call(
  user: current_user,
  params: property_params
)

if result.success?
  # Handle success
else
  # Handle failure
end
```

### Query Objects
Complex database queries are encapsulated in query objects:

```ruby
# Example usage
properties = PropertiesQuery.new
  .search("downtown")
  .price_range(1000, 2000)
  .with_amenities(["parking", "gym"])
  .available
  .execute
```

### Caching Strategy
Multi-level caching for optimal performance:
- **Application-level**: Fragment caching for views
- **Database-level**: Query result caching
- **API-level**: Response caching with ETags
- **CDN-level**: Static asset caching

## 📚 API Documentation

### Authentication
```bash
# Login
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "password"
}

# Response includes JWT token
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { ... }
}
```

### Properties Endpoints
```bash
# List properties
GET /api/v1/properties
Authorization: Bearer <token>

# Create property
POST /api/v1/properties
Authorization: Bearer <token>
{
  "property": {
    "title": "Modern Downtown Apartment",
    "description": "...",
    "price": 2500,
    "bedrooms": 2,
    "bathrooms": 1
  }
}

# Search properties
GET /api/v1/properties/search?q=downtown&min_price=1000&max_price=3000
```

Full API documentation available at `/api-docs` when running the application.

## 🧪 Testing

### Run the test suite
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/services/properties/create_service_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec
```

### Code Quality Checks
```bash
# Run RuboCop for code style
bundle exec rubocop

# Run Brakeman for security analysis
bundle exec brakeman

# Run bundler-audit for dependency vulnerabilities
bundle audit

# Run all checks
rake quality
```

## 📦 Deployment

### Heroku Deployment
```bash
# Create Heroku app
heroku create ofie-web-api

# Add PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# Add Redis for Action Cable
heroku addons:create heroku-redis:hobby-dev

# Set environment variables
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
heroku config:set JWT_SECRET_KEY=your-secret-key

# Deploy
git push heroku main

# Run migrations
heroku run rails db:migrate

# Scale workers for background jobs
heroku ps:scale worker=1
```

### Docker Deployment
```bash
# Build Docker image
docker build -t ofie-web-api .

# Run with Docker Compose
docker-compose up
```

## 🔒 Security Features

- **Authentication**: JWT tokens with expiration and refresh
- **Authorization**: Role-based access control with Pundit
- **Rate Limiting**: Rack::Attack configured for API endpoints
- **SQL Injection Protection**: Parameterized queries throughout
- **XSS Protection**: Content Security Policy headers
- **CSRF Protection**: Rails CSRF tokens for web forms
- **Encrypted Secrets**: Rails credentials for sensitive data
- **Input Validation**: Strong parameters and model validations
- **File Upload Security**: Whitelist allowed file types
- **SSL/TLS**: Force SSL in production

## 🗂 Project Structure

```
ofie-web-api/
├── app/
│   ├── controllers/       # API and web controllers
│   ├── models/            # ActiveRecord models
│   ├── services/          # Business logic services
│   ├── queries/           # Database query objects
│   ├── jobs/              # Background jobs
│   ├── mailers/           # Email handlers
│   ├── views/             # ERB templates
│   └── javascript/        # Stimulus controllers
├── config/
│   ├── routes.rb          # Application routes
│   ├── database.yml       # Database configuration
│   └── application.rb     # Rails configuration
├── db/
│   ├── migrate/           # Database migrations
│   ├── schema.rb          # Database schema
│   └── seeds.rb           # Seed data
├── spec/                  # RSpec tests
├── public/                # Static files
└── lib/                   # Custom libraries
```

## 🚀 Performance Optimizations

- **Database Indexes**: 40+ optimized indexes for common queries
- **N+1 Query Prevention**: Bullet gem in development
- **Eager Loading**: Includes and preload associations
- **Fragment Caching**: Cache expensive view partials
- **Russian Doll Caching**: Nested cache dependencies
- **Background Jobs**: Async processing for heavy operations
- **CDN Integration**: CloudFront for static assets
- **Image Optimization**: Variant processing with Active Storage
- **Pagination**: Kaminari for efficient data loading
- **Database Connection Pooling**: Optimized pool size

## 🐛 Troubleshooting

### Common Issues

#### Database connection errors
```bash
# Check PostgreSQL is running
pg_ctl status

# Reset database
rails db:drop db:create db:migrate
```

#### Asset compilation issues
```bash
# Precompile assets
rails assets:precompile

# Clean and rebuild
rails assets:clobber assets:precompile
```

#### Background job issues
```bash
# Check Solid Queue status
rails solid_queue:status

# Clear stuck jobs
rails solid_queue:clear
```

## 📝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Lead Developer**: [Your Name]
- **Backend Engineer**: [Team Member]
- **Frontend Developer**: [Team Member]
- **UI/UX Designer**: [Team Member]

## 🙏 Acknowledgments

- Rails Community for the amazing framework
- All contributors who have helped shape this project
- Open source libraries that power this application

## 📧 Contact

For questions and support, please contact:
- Email: support@ofie.com
- Website: [www.ofie.com](https://www.ofie.com)
- Issues: [GitHub Issues](https://github.com/yourusername/ofie-web-api/issues)

---

**Built with ❤️ using Ruby on Rails**