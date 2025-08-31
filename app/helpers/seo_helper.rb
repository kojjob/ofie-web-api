# SEO Helper Module
# Provides view helpers for SEO tags and structured data
module SeoHelper
  # Generate all meta tags for the head section
  def render_meta_tags
    tags = []
    
    # Basic meta tags
    tags << tag(:meta, name: 'description', content: meta_description) if meta_description.present?
    tags << tag(:meta, name: 'keywords', content: meta_keywords) if meta_keywords.present?
    
    # Robots meta tag
    tags << tag(:meta, name: 'robots', content: robots_meta) if robots_meta.present?
    
    # Open Graph tags
    tags << tag(:meta, property: 'og:title', content: og_title) if og_title.present?
    tags << tag(:meta, property: 'og:description', content: og_description) if og_description.present?
    tags << tag(:meta, property: 'og:image', content: og_image) if og_image.present?
    tags << tag(:meta, property: 'og:url', content: og_url) if og_url.present?
    tags << tag(:meta, property: 'og:type', content: og_type)
    tags << tag(:meta, property: 'og:site_name', content: 'Ofie')
    tags << tag(:meta, property: 'og:locale', content: 'en_US')
    
    # Twitter Card tags
    tags << tag(:meta, name: 'twitter:card', content: twitter_card)
    tags << tag(:meta, name: 'twitter:title', content: twitter_title) if twitter_title.present?
    tags << tag(:meta, name: 'twitter:description', content: twitter_description) if twitter_description.present?
    tags << tag(:meta, name: 'twitter:image', content: twitter_image) if twitter_image.present?
    tags << tag(:meta, name: 'twitter:site', content: '@ofie_platform')
    
    # Canonical URL
    tags << tag(:link, rel: 'canonical', href: canonical_url) if canonical_url.present?
    
    # Alternate language links
    alternate_languages.each do |lang|
      tags << tag(:link, rel: 'alternate', hreflang: lang[:code], href: lang[:url])
    end
    
    safe_join(tags, "\n")
  end

  # Render structured data scripts
  def render_structured_data
    return nil unless structured_data_json.present?
    
    scripts = structured_data_json.map do |data|
      content_tag(:script, data.html_safe, type: 'application/ld+json')
    end
    
    safe_join(scripts, "\n")
  end

  # Render breadcrumb structured data
  def render_breadcrumb_structured_data
    return nil unless respond_to?(:breadcrumb_json) && breadcrumb_json.present?
    
    content_tag(:script, breadcrumb_json.html_safe, type: 'application/ld+json')
  end

  # Generate organization structured data
  def organization_structured_data
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "Ofie",
      "url": root_url,
      "logo": image_url('logo.png'),
      "sameAs": [
        "https://twitter.com/ofie_platform",
        "https://www.facebook.com/ofie",
        "https://www.linkedin.com/company/ofie"
      ],
      "contactPoint": {
        "@type": "ContactPoint",
        "telephone": "+1-555-0123",
        "contactType": "customer service",
        "availableLanguage": ["English"]
      }
    }
  end

  # Generate website search action structured data
  def website_search_structured_data
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "url": root_url,
      "potentialAction": {
        "@type": "SearchAction",
        "target": {
          "@type": "EntryPoint",
          "urlTemplate": "#{root_url}properties?q={search_term_string}"
        },
        "query-input": "required name=search_term_string"
      }
    }
  end

  # Generate property structured data
  def property_structured_data(property)
    {
      "@context": "https://schema.org",
      "@type": "RealEstateListing",
      "name": property.title,
      "description": property.description,
      "url": property_url(property),
      "datePosted": property.created_at.iso8601,
      "dateModified": property.updated_at.iso8601,
      "offers": {
        "@type": "Offer",
        "price": property.price,
        "priceCurrency": "USD",
        "availability": property.available? ? "https://schema.org/InStock" : "https://schema.org/OutOfStock"
      },
      "address": {
        "@type": "PostalAddress",
        "streetAddress": property.address,
        "addressLocality": property.city,
        "addressRegion": property.state,
        "postalCode": property.zip_code,
        "addressCountry": "US"
      },
      "numberOfRooms": property.bedrooms,
      "numberOfBathroomsTotal": property.bathrooms,
      "floorSize": {
        "@type": "QuantitativeValue",
        "value": property.square_feet,
        "unitCode": "FTK"
      },
      "image": (property.images.map { |img| url_for(img) } rescue []),
      "geo": property.latitude.present? && property.longitude.present? ? {
        "@type": "GeoCoordinates",
        "latitude": property.latitude,
        "longitude": property.longitude
      } : nil
    }.compact
  end

  # Generate FAQ structured data
  def faq_structured_data(faqs)
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      "mainEntity": faqs.map do |faq|
        {
          "@type": "Question",
          "name": faq[:question],
          "acceptedAnswer": {
            "@type": "Answer",
            "text": faq[:answer]
          }
        }
      end
    }
  end

  # Generate local business structured data
  def local_business_structured_data
    {
      "@context": "https://schema.org",
      "@type": "RealEstateAgent",
      "name": "Ofie Real Estate",
      "image": image_url('logo.png'),
      "@id": root_url,
      "url": root_url,
      "telephone": "+1-555-0123",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "123 Main Street",
        "addressLocality": "San Francisco",
        "addressRegion": "CA",
        "postalCode": "94105",
        "addressCountry": "US"
      },
      "geo": {
        "@type": "GeoCoordinates",
        "latitude": 37.7749,
        "longitude": -122.4194
      },
      "openingHoursSpecification": {
        "@type": "OpeningHoursSpecification",
        "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
        "opens": "09:00",
        "closes": "18:00"
      },
      "sameAs": [
        "https://twitter.com/ofie_platform",
        "https://www.facebook.com/ofie",
        "https://www.linkedin.com/company/ofie"
      ]
    }
  end

  # Helper to generate JSON-LD script tag
  def json_ld_tag(data)
    content_tag(:script, data.to_json.html_safe, type: 'application/ld+json')
  end

  # Helper to truncate text for meta descriptions
  def meta_truncate(text, length = 160)
    return '' if text.blank?
    
    truncated = text.gsub(/\s+/, ' ').strip
    if truncated.length > length
      truncated = truncated[0...length].gsub(/\s\w+\s*$/, '')
      "#{truncated}..."
    else
      truncated
    end
  end

  # Helper to generate social sharing URLs
  def social_share_url(platform, url, title = nil, description = nil)
    encoded_url = CGI.escape(url)
    encoded_title = CGI.escape(title || '')
    encoded_description = CGI.escape(description || '')
    
    case platform.to_sym
    when :facebook
      "https://www.facebook.com/sharer/sharer.php?u=#{encoded_url}"
    when :twitter
      "https://twitter.com/intent/tweet?url=#{encoded_url}&text=#{encoded_title}"
    when :linkedin
      "https://www.linkedin.com/sharing/share-offsite/?url=#{encoded_url}"
    when :whatsapp
      "https://wa.me/?text=#{encoded_title}%20#{encoded_url}"
    when :pinterest
      "https://pinterest.com/pin/create/button/?url=#{encoded_url}&description=#{encoded_description}"
    else
      '#'
    end
  end
end