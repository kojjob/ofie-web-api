class HomeController < ApplicationController
  include SiteConfigHelper

  skip_before_action :authenticate_request, only: [ :index, :about, :help, :contact, :terms_of_service, :privacy_policy, :cookie_policy, :accessibility, :tenant_screening, :neighborhoods, :renter_resources, :careers, :press ]

  def index
    # Featured properties for the landing page
    @featured_properties = Property.where(availability_status: "available")
                                  .includes(:photos_attachments)
                                  .limit(6)
                                  .order(created_at: :desc)

    # Dynamic statistics for the hero section
    @total_properties = Property.count
    @available_properties = Property.where(availability_status: "available").count
    @total_users = User.count
    @cities_count = Property.distinct.count(:city)

    # Load site configuration for view
    @site_config = site_config
  end

  def about
    @page_title = "About Ofie"
    @page_description = "Learn about our mission to revolutionize real estate through technology and trust."
  end

  def help
    @page_title = "Help Center"
    @page_description = "Find answers to common questions and get support for using our platform."
  end

  def contact
    @page_title = "Contact Us"
    @page_description = "Get in touch with our support team for assistance with your property needs."
  end

  def terms_of_service
    @page_title = "Terms of Service"
    @page_description = "Read our terms of service and user agreement."
  end

  def privacy_policy
    @page_title = "Privacy Policy"
    @page_description = "Learn how we protect and handle your personal information."
  end

  def cookie_policy
    @page_title = "Cookie Policy"
    @page_description = "Understand how we use cookies to improve your experience."
  end

  def accessibility
    @page_title = "Accessibility"
    @page_description = "Our commitment to making our platform accessible to everyone."
  end

  def tenant_screening
    @page_title = "Tenant Screening"
    @page_description = "Comprehensive tenant screening services for landlords."
  end

  def neighborhoods
    @page_title = "Neighborhood Guides"
    @page_description = "Explore different neighborhoods and find the perfect area for your next home."
  end

  def renter_resources
    @page_title = "Renter Resources"
    @page_description = "Essential resources and guides for renters to navigate the rental process."
  end

  def careers
    @page_title = "Careers"
    @page_description = "Join our team and help revolutionize the real estate industry."
  end

  def press
    @page_title = "Press & Media"
    @page_description = "Latest news, press releases, and media coverage about Ofie."
  end
end
