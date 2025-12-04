class CspReportsController < ApplicationController
  skip_before_action :authenticate_request
  # CSP reports need to accept POST without CSRF token
  protect_from_forgery with: :null_session

  def create
    # Log the CSP violation report for monitoring purposes
    if params["csp-report"].present?
      report = params["csp-report"]

      Rails.logger.warn "CSP Violation Report:"
      Rails.logger.warn "  Document URI: #{report['document-uri']}"
      Rails.logger.warn "  Blocked URI: #{report['blocked-uri']}"
      Rails.logger.warn "  Violated Directive: #{report['violated-directive']}"
      Rails.logger.warn "  Original Policy: #{report['original-policy']}"
      Rails.logger.warn "  Script Sample: #{report['script-sample']}" if report["script-sample"]

      # In production, you might want to send these to a monitoring service
      # like Sentry, Bugsnag, or store them in a database for analysis
      if Rails.env.production?
        # Example: Send to monitoring service
        # Sentry.capture_message("CSP Violation", extra: report)
      end
    end

    head :no_content
  end

  private

  def skip_auth?
    # Skip authentication for CSP reports
    true
  end
end
