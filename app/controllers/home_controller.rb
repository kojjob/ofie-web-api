class HomeController < ApplicationController
  include SiteConfigHelper

  skip_before_action :authenticate_request, only: [ :index, :about, :help, :contact, :terms_of_service, :privacy_policy, :cookie_policy, :accessibility, :tenant_screening, :neighborhoods, :renter_resources, :careers, :press ]

  def index
    # Set comprehensive SEO meta tags for homepage
    set_meta_tags(
      title: "Find Your Perfect Rental Property",
      description: "Discover thousands of verified rental properties. Browse apartments, houses, and condos with our intelligent search platform. Join 25,000+ satisfied families.",
      keywords: "rental properties, apartments for rent, houses for rent, property search, real estate rentals, find rentals near me",
      og: {
        title: "Ofie - Your Dream Home Awaits",
        description: "Browse thousands of verified rental listings with instant matches and premium quality properties.",
        type: "website",
        image: (helpers.image_url("og-homepage.png") rescue nil)
      },
      twitter: {
        card: "summary_large_image",
        title: "Find Your Perfect Rental on Ofie",
        description: "Join 25,000+ families who found their dream home with our premium rental platform."
      }
    )

    # Add structured data for homepage
    add_structured_data(organization_structured_data)
    add_structured_data(website_search_structured_data)
    add_structured_data(local_business_structured_data)

    # Add breadcrumbs
    add_breadcrumb("Home")

    # Featured properties for the landing page
    @featured_properties = Property.where(availability_status: "available")
                                  .with_attached_photos
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

    set_meta_tags(
      title: "About Ofie - Leading Property Rental Platform",
      description: "Learn about Ofie, the premium property rental platform connecting landlords and tenants. Our mission is to make finding your perfect home simple and secure.",
      keywords: "about ofie, property rental platform, rental marketplace, real estate technology",
      og: {
        title: "About Ofie - Your Trusted Rental Partner",
        description: "Discover how Ofie is revolutionizing the rental market with technology and trust.",
        type: "website"
      }
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("About")
  end

  def help
    @page_title = "Help Center"
    @page_description = "Find answers to common questions and get support for using our platform."

    set_meta_tags(
      title: "Help Center - Ofie Support & Resources",
      description: "Find answers to common questions about using Ofie. Browse our help articles, FAQs, and guides for tenants and landlords.",
      keywords: "help center, FAQ, rental guide, tenant help, landlord resources",
      robots: "index, follow, max-snippet:-1"
    )

    # Add FAQ structured data
    add_structured_data(faq_structured_data)

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Help")
  end

  def contact
    @page_title = "Contact Us"
    @page_description = "Get in touch with our support team for assistance with your property needs."

    set_meta_tags(
      title: "Contact Us - Get in Touch with Ofie",
      description: "Have questions? Contact the Ofie team for support with property listings, rental applications, or general inquiries. We are here to help 24/7.",
      keywords: "contact ofie, customer support, rental help, property questions",
      og: {
        title: "Contact Ofie - We are Here to Help",
        description: "Get in touch with our support team for any questions about rentals or listings."
      }
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Contact")
  end

  def terms_of_service
    @page_title = "Terms of Service"
    @page_description = "Read our terms of service and user agreement."

    set_meta_tags(
      title: "Terms of Service - Ofie",
      description: "Read the Ofie terms of service and user agreement. Understand your rights and responsibilities when using our platform.",
      robots: "noindex, follow"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Terms of Service")
  end

  def privacy_policy
    @page_title = "Privacy Policy"
    @page_description = "Learn how we protect and handle your personal information."

    set_meta_tags(
      title: "Privacy Policy - Ofie",
      description: "Learn how Ofie protects your privacy and handles your personal information. Our commitment to data security and user privacy.",
      robots: "noindex, follow"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Privacy Policy")
  end

  def cookie_policy
    @page_title = "Cookie Policy"
    @page_description = "Understand how we use cookies to improve your experience."

    set_meta_tags(
      title: "Cookie Policy - Ofie",
      description: "Learn about how Ofie uses cookies and similar technologies to improve your browsing experience.",
      robots: "noindex, follow"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Cookie Policy")
  end

  def accessibility
    @page_title = "Accessibility"
    @page_description = "Our commitment to making our platform accessible to everyone."

    set_meta_tags(
      title: "Accessibility Statement - Ofie",
      description: "Learn about Ofie commitment to digital accessibility and making our platform usable for everyone.",
      keywords: "accessibility, ADA compliance, WCAG, inclusive design"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Accessibility")
  end

  def tenant_screening
    @page_title = "Tenant Screening"
    @page_description = "Comprehensive tenant screening services for landlords."

    set_meta_tags(
      title: "Tenant Screening Services - Background Checks & Verification",
      description: "Professional tenant screening services including credit checks, background verification, and rental history. Protect your property with comprehensive screening.",
      keywords: "tenant screening, background check, credit check, rental verification, tenant verification"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Tenant Screening")
  end

  def neighborhoods
    @page_title = "Neighborhood Guides"
    @page_description = "Explore different neighborhoods and find the perfect area for your next home."

    set_meta_tags(
      title: "Neighborhood Guides - Find the Perfect Area",
      description: "Explore comprehensive neighborhood guides. Discover local amenities, schools, transportation, and community features to find your ideal location.",
      keywords: "neighborhood guide, area information, local amenities, school districts, community features"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Neighborhoods")

    # Get all cities with property counts
    @neighborhoods = Property.where(availability_status: "available")
                             .group(:city)
                             .select("city, COUNT(*) as property_count,
                                     AVG(price) as avg_rent,
                                     MIN(price) as min_rent,
                                     MAX(price) as max_rent")
                             .having("city IS NOT NULL")
                             .order("property_count DESC")
  end

  def renter_resources
    @page_title = "Renter Resources"
    @page_description = "Essential resources and guides for renters to navigate the rental process."

    set_meta_tags(
      title: "Renter Resources - Guides & Tools for Tenants",
      description: "Essential resources for renters including guides, checklists, and tools to help navigate the rental process from search to move-in.",
      keywords: "renter resources, tenant guide, rental tips, moving checklist, tenant rights"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Renter Resources")
  end

  def careers
    @page_title = "Careers"
    @page_description = "Join our team and help revolutionize the real estate industry."

    set_meta_tags(
      title: "Careers at Ofie - Join Our Team",
      description: "Explore career opportunities at Ofie. Join our team and help revolutionize the real estate industry with technology and innovation.",
      keywords: "careers, jobs, employment, real estate careers, tech jobs"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Careers")
  end

  def press
    @page_title = "Press & Media"
    @page_description = "Latest news, press releases, and media coverage about Ofie."

    set_meta_tags(
      title: "Press & Media - Ofie News and Coverage",
      description: "Latest news, press releases, and media coverage about Ofie. Media kit, company information, and press contact details.",
      keywords: "press, media, news, press releases, media coverage, company news"
    )

    add_breadcrumb("Home", root_path)
    add_breadcrumb("Press")
  end

  private

  def organization_structured_data
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "Ofie",
      "url": root_url,
      "logo": (helpers.image_url("logo.png") rescue root_url),
      "description": "Premium property rental platform connecting landlords and tenants",
      "address": {
        "@type": "PostalAddress",
        "addressLocality": "San Francisco",
        "addressRegion": "CA",
        "addressCountry": "US"
      },
      "sameAs": [
        "https://twitter.com/ofie_platform",
        "https://www.facebook.com/ofie",
        "https://www.linkedin.com/company/ofie"
      ]
    }
  end

  def website_search_structured_data
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "name": "Ofie",
      "url": root_url,
      "potentialAction": {
        "@type": "SearchAction",
        "target": {
          "@type": "EntryPoint",
          "urlTemplate": "#{properties_url}?q={search_term_string}"
        },
        "query-input": "required name=search_term_string"
      }
    }
  end

  def local_business_structured_data
    {
      "@context": "https://schema.org",
      "@type": "RealEstateAgent",
      "name": "Ofie Real Estate",
      "image": (helpers.image_url("logo.png") rescue root_url),
      "url": root_url,
      "telephone": "+1-555-0123",
      "priceRange": "$$",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "123 Main Street",
        "addressLocality": "San Francisco",
        "addressRegion": "CA",
        "postalCode": "94105",
        "addressCountry": "US"
      },
      "openingHoursSpecification": {
        "@type": "OpeningHoursSpecification",
        "dayOfWeek": [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" ],
        "opens": "09:00",
        "closes": "18:00"
      }
    }
  end

  def faq_structured_data
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      "mainEntity": [
        {
          "@type": "Question",
          "name": "How do I list my property on Ofie?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "Creating a listing on Ofie is simple. Sign up for a landlord account, click 'List Property', fill in the details, upload photos, and publish. Your listing will be live within minutes."
          }
        },
        {
          "@type": "Question",
          "name": "Is Ofie free for tenants?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "Yes, Ofie is completely free for tenants. You can browse properties, submit applications, and communicate with landlords at no cost."
          }
        },
        {
          "@type": "Question",
          "name": "How does the tenant screening process work?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "Our tenant screening includes credit checks, background verification, employment verification, and rental history. Results are typically available within 24-48 hours."
          }
        },
        {
          "@type": "Question",
          "name": "What payment methods are accepted?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "We accept all major credit cards, debit cards, and ACH bank transfers for rent payments and application fees."
          }
        }
      ]
    }
  end
end
