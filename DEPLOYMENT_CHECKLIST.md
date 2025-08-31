# Deployment Checklist for Ofie Web API

## Pre-Deployment Checklist

### Code Preparation
- [ ] All features are tested and working locally
- [ ] Code is committed and pushed to repository
- [ ] Branch is merged to main/production branch
- [ ] Version tags are created if applicable

### Environment Configuration
- [ ] `.env` file is created from `.env.example`
- [ ] `RAILS_MASTER_KEY` is set correctly
- [ ] `DATABASE_URL` is configured with production database
- [ ] `APP_DOMAIN` is set to production domain
- [ ] Email credentials (`SMTP_*`) are configured
- [ ] Stripe keys are set (if using payments)
- [ ] AWS credentials are set (for Active Storage)
- [ ] Sentry DSN is configured (for error monitoring)

### Database
- [ ] Production database server is running
- [ ] Database user has proper permissions
- [ ] Database backups are configured
- [ ] Migration files are reviewed and tested

### Security
- [ ] SSL certificate is ready or Let's Encrypt is configured
- [ ] CORS origins are properly configured
- [ ] Security headers are enabled
- [ ] Rate limiting is configured
- [ ] Sensitive data is not in version control

## Deployment Steps

### 1. Server Preparation
- [ ] Server meets minimum requirements (2GB RAM, 20GB disk)
- [ ] Docker is installed on server
- [ ] Required ports are open (80, 443, 22)
- [ ] Server IP is added to `config/deploy.yml`

### 2. Initial Deployment
```bash
# Run these commands in order:
- [ ] kamal setup           # First time only
- [ ] kamal env push       # Push environment variables
- [ ] kamal deploy         # Deploy application
- [ ] kamal app exec 'rails db:create'  # Create databases
- [ ] kamal app exec 'rails db:migrate' # Run migrations
```

### 3. Verification
- [ ] Health check endpoint responds: `curl https://your-domain.com/health`
- [ ] Application loads in browser
- [ ] SSL certificate is valid
- [ ] Login/Registration works
- [ ] File uploads work (Active Storage)
- [ ] Email sending works
- [ ] Background jobs are processing

### 4. Monitoring Setup
- [ ] Sentry is receiving error reports
- [ ] Application logs are accessible
- [ ] Database queries are performing well
- [ ] Server resources are adequate

## Post-Deployment Checklist

### Immediate Tasks
- [ ] Verify all critical features work
- [ ] Check error logs for any issues
- [ ] Monitor server resources (CPU, Memory, Disk)
- [ ] Verify email delivery
- [ ] Test payment processing (if applicable)
- [ ] Check background job processing

### Within 24 Hours
- [ ] Review Sentry for any errors
- [ ] Check application performance metrics
- [ ] Verify backups are running
- [ ] Review security scan results
- [ ] Update DNS records if needed
- [ ] Configure CDN if applicable

### Ongoing Maintenance
- [ ] Set up automated backups
- [ ] Configure log rotation
- [ ] Set up uptime monitoring
- [ ] Plan for scaling strategy
- [ ] Document any custom configurations
- [ ] Schedule regular security updates

## Rollback Plan

If issues are encountered:

1. **Quick Rollback**
   ```bash
   kamal rollback
   ```

2. **Database Rollback** (if migrations fail)
   ```bash
   kamal app exec 'rails db:rollback STEP=n'
   ```

3. **Full Recovery**
   - Restore database from backup
   - Deploy previous known good version
   - Review logs to identify issue
   - Fix and redeploy

## Emergency Contacts

- **Server Admin**: [Contact info]
- **Database Admin**: [Contact info]
- **DevOps Lead**: [Contact info]
- **On-call Developer**: [Contact info]

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Application won't start | Check logs with `kamal app logs`, verify env variables |
| Database connection failed | Verify DATABASE_URL, check network connectivity |
| Assets not loading | Run `rails assets:precompile`, check asset pipeline |
| SSL not working | Verify domain DNS, check port 443, review proxy logs |
| Emails not sending | Check SMTP credentials, verify email service |
| Jobs not processing | Check Solid Queue status, review job logs |
| Out of memory | Increase server RAM, optimize Puma workers |
| Slow performance | Check database queries, enable caching, scale servers |

## Notes

- Always test deployments on staging first if available
- Keep master key secure and backed up
- Document any custom server configurations
- Maintain separate development, staging, and production environments
- Regular backups are critical - test restore procedures

## Sign-off

- [ ] Deployment completed successfully
- [ ] All checks passed
- [ ] Documentation updated
- [ ] Team notified

**Deployed by**: _________________
**Date**: _________________
**Version**: _________________