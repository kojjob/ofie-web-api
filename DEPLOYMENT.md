# Ofie Web API - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Database Setup](#database-setup)
4. [Deployment with Kamal](#deployment-with-kamal)
5. [Post-Deployment](#post-deployment)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- Docker (v20.10+)
- Ruby 3.4.3
- PostgreSQL 15+
- Redis (optional, for ActionCable)
- Git

### Server Requirements
- Ubuntu 22.04 LTS or similar
- Minimum 2GB RAM
- 20GB disk space
- Open ports: 80, 443, 22

## Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/ofie-web-api.git
cd ofie-web-api
```

### 2. Install Dependencies
```bash
bundle install
npm install # or yarn install
```

### 3. Configure Environment Variables
Copy the example environment file and configure it:
```bash
cp .env.example .env
```

Required environment variables:
- `RAILS_MASTER_KEY` - From config/master.key
- `DATABASE_URL` - PostgreSQL connection string
- `APP_DOMAIN` - Your production domain
- `STRIPE_SECRET_KEY` - Stripe API key
- `SMTP_USER_NAME` - Email service credentials
- `AWS_ACCESS_KEY_ID` - For Active Storage

### 4. Setup Rails Credentials
```bash
# Run the setup script
./bin/setup-credentials

# Or manually edit credentials
EDITOR='nano' rails credentials:edit
```

## Database Setup

### 1. Create Production Database
```bash
# On your database server
createdb ofie_web_api_production
createdb ofie_web_api_production_cache
createdb ofie_web_api_production_queue
createdb ofie_web_api_production_cable
```

### 2. Run Migrations
```bash
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:migrate:cable
RAILS_ENV=production rails db:migrate:queue
RAILS_ENV=production rails db:migrate:cache
```

### 3. Seed Initial Data (Optional)
```bash
RAILS_ENV=production rails db:seed
```

## Deployment with Kamal

### 1. Initial Setup
```bash
# Install Kamal
gem install kamal

# Configure deployment
# Edit config/deploy.yml with your server details
```

### 2. Build and Push Docker Image
```bash
# Login to Docker Hub
docker login

# Build image
kamal build push
```

### 3. Server Setup
```bash
# Setup server (first time only)
kamal setup

# This will:
# - Install Docker on the server
# - Setup network
# - Create necessary directories
```

### 4. Deploy Application
```bash
# Deploy the application
kamal deploy

# For zero-downtime deployment
kamal deploy --skip-push
```

### 5. Database Setup on Server
```bash
# Run migrations on server
kamal app exec 'rails db:migrate'

# Create cache/queue/cable databases
kamal app exec 'rails db:create:all'
```

## Post-Deployment

### 1. Verify Deployment
```bash
# Check application status
kamal app details

# Check logs
kamal app logs

# Access Rails console
kamal app exec -i 'rails console'
```

### 2. Setup SSL with Let's Encrypt
Kamal automatically handles SSL certificates via Let's Encrypt when configured in `config/deploy.yml`:
```yaml
proxy:
  ssl: true
  host: your-domain.com
```

### 3. Configure Monitoring
- Health check endpoint: `https://your-domain.com/health`
- Sentry for error tracking (configured via SENTRY_DSN)
- Application logs available via: `kamal app logs -f`

### 4. Setup Cron Jobs (if needed)
```bash
# Add to server crontab
kamal app exec 'whenever --update-crontab'
```

## Monitoring

### Health Check
The application provides a health check endpoint at `/health` that monitors:
- Database connectivity
- Redis connectivity (if configured)
- Disk space
- Memory usage
- Active Storage service

### Error Monitoring
Sentry is configured for production error tracking:
1. Set `SENTRY_DSN` in environment variables
2. Errors are automatically reported
3. View dashboard at sentry.io

### Application Logs
```bash
# View logs
kamal app logs -f

# View specific service logs
kamal app logs -f --roles web
kamal app logs -f --roles job
```

### Performance Monitoring
- Monitor response times via Rails logs
- Track Solid Queue job processing
- Monitor database query performance

## Common Operations

### Update Application
```bash
# Pull latest code
git pull origin main

# Deploy update
kamal deploy
```

### Rollback
```bash
# Rollback to previous version
kamal rollback
```

### Scale Application
```bash
# Edit config/deploy.yml to add more servers
# Then redeploy
kamal deploy
```

### Database Backup
```bash
# Create backup
kamal app exec 'pg_dump $DATABASE_URL > backup.sql'

# Download backup
kamal app download backup.sql
```

### Rails Console Access
```bash
kamal app exec -i 'rails console'
```

## Troubleshooting

### Application Won't Start
1. Check logs: `kamal app logs`
2. Verify environment variables: `kamal env push`
3. Check database connectivity
4. Verify master key is correct

### Database Connection Issues
1. Verify DATABASE_URL is correct
2. Check PostgreSQL is running
3. Verify network connectivity
4. Check database permissions

### Asset Compilation Issues
1. Precompile assets locally: `rails assets:precompile`
2. Check for JavaScript errors
3. Verify all asset dependencies are installed

### SSL Certificate Issues
1. Verify domain DNS points to server
2. Check port 80/443 are open
3. Review Kamal proxy logs: `kamal proxy logs`

### Memory Issues
1. Check server memory: `kamal server exec 'free -h'`
2. Adjust Puma workers in `config/puma.rb`
3. Consider adding swap space

## Security Checklist

- [ ] Master key is secure and not in version control
- [ ] Database uses strong passwords
- [ ] SSL is enabled and working
- [ ] CORS is properly configured
- [ ] Security headers are enabled
- [ ] Rate limiting is configured
- [ ] Sensitive data is encrypted
- [ ] Regular security updates are applied
- [ ] Backup strategy is in place
- [ ] Monitoring and alerting is configured

## Support

For deployment issues:
1. Check application logs
2. Review Sentry error reports
3. Consult Rails and Kamal documentation
4. Open an issue on GitHub

## Additional Resources

- [Kamal Documentation](https://kamal-deploy.org/)
- [Rails Deployment Guide](https://guides.rubyonrails.org/configuring.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)