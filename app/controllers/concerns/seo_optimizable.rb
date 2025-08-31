# SEO Optimization Module for Controllers
# Provides comprehensive SEO functionality including meta tags, structured data, and canonical URLs
module SeoOptimizable
  extend ActiveSupport::Concern

  included do
    helper_method :meta_title, :meta_description, :meta_keywords,
                  :og_title, :og_description, :og_image, :og_url, :og_type,
                  :twitter_card, :twitter_title, :twitter_description, :twitter_image,
                  :canonical_url, :robots_meta, :structured_data_json,
                  :alternate_languages, :breadcrumb_json

    before_action :set_default_meta_tags
  end

  private

  def set_default_meta_tags
    @meta_tags = {
      title: default_meta_title,
      description: default_meta_description,
      keywords: default_meta_keywords,
      og: default_og_tags,
      twitter: default_twitter_tags,
      canonical: request.original_url,
      robots: "index, follow",
      alternate_languages: [],
      structured_data: []
    }
  end

  def set_meta_tags(options = {})
    @meta_tags ||= {}

    # Basic meta tags
    @meta_tags[:title] = options[:title] if options[:title].present?
    @meta_tags[:description] = options[:description] if options[:description].present?
    @meta_tags[:keywords] = options[:keywords] if options[:keywords].present?

    # Open Graph tags
    if options[:og].present?
      @meta_tags[:og] ||= {}
      @meta_tags[:og].merge!(options[:og])
    end

    # Twitter Card tags
    if options[:twitter].present?
      @meta_tags[:twitter] ||= {}
      @meta_tags[:twitter].merge!(options[:twitter])
    end

    # Other SEO tags
    @meta_tags[:canonical] = options[:canonical] if options[:canonical].present?
    @meta_tags[:robots] = options[:robots] if options[:robots].present?
    @meta_tags[:alternate_languages] = options[:alternate_languages] if options[:alternate_languages].present?

    # Structured data
    add_structured_data(options[:structured_data]) if options[:structured_data].present?
  end

  def add_structured_data(data)
    @meta_tags[:structured_data] ||= []
    @meta_tags[:structured_data] << data
  end

  # Meta tag accessors
  def meta_title
    title = @meta_tags&.dig(:title) || default_meta_title
    "#{title} | #{site_name}"
  end

  def meta_description
    @meta_tags&.dig(:description) || default_meta_description
  end

  def meta_keywords
    @meta_tags&.dig(:keywords) || default_meta_keywords
  end

  # Open Graph accessors
  def og_title
    @meta_tags&.dig(:og, :title) || meta_title
  end

  def og_description
    @meta_tags&.dig(:og, :description) || meta_description
  end

  def og_image
    image = @meta_tags&.dig(:og, :image)
    return image if image.present?

    # Default OG image
    helpers.image_url("og-default.png") rescue nil
  end

  def og_url
    @meta_tags&.dig(:og, :url) || canonical_url
  end

  def og_type
    @meta_tags&.dig(:og, :type) || "website"
  end

  # Twitter Card accessors
  def twitter_card
    @meta_tags&.dig(:twitter, :card) || "summary_large_image"
  end

  def twitter_title
    @meta_tags&.dig(:twitter, :title) || og_title
  end

  def twitter_description
    @meta_tags&.dig(:twitter, :description) || og_description
  end

  def twitter_image
    @meta_tags&.dig(:twitter, :image) || og_image
  end

  # Canonical URL
  def canonical_url
    url = @meta_tags&.dig(:canonical)
    return url if url.present?

    # Build canonical URL from current request
    "#{request.protocol}#{request.host_with_port}#{request.path}"
  end

  # Robots meta
  def robots_meta
    @meta_tags&.dig(:robots) || "index, follow"
  end

  # Alternate languages for international SEO
  def alternate_languages
    @meta_tags&.dig(:alternate_languages) || []
  end

  # Structured data JSON-LD
  def structured_data_json
    return nil unless @meta_tags&.dig(:structured_data).present?

    data = @meta_tags[:structured_data]
    data = [ data ] unless data.is_a?(Array)

    data.map do |item|
      item.is_a?(String) ? item : item.to_json
    end
  end

  # Breadcrumb structured data
  def breadcrumb_json
    return nil unless @breadcrumbs.present?

    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": @breadcrumbs.map.with_index do |crumb, index|
        {
          "@type": "ListItem",
          "position": index + 1,
          "name": crumb[:name],
          "item": crumb[:url]
        }
      end
    }.to_json
  end

  # Helper method to add breadcrumb
  def add_breadcrumb(name, url = nil)
    @breadcrumbs ||= []
    @breadcrumbs << { name: name, url: url }
  end

  # Default values
  def default_meta_title
    controller_name.humanize
  end

  def default_meta_description
    "Find your perfect rental property with Ofie. Browse thousands of verified listings, apply online, and manage your rental journey."
  end

  def default_meta_keywords
    "rental properties, apartments for rent, houses for rent, property management, real estate, #{controller_name}"
  end

  def default_og_tags
    {
      title: default_meta_title,
      description: default_meta_description,
      type: "website",
      site_name: site_name,
      locale: "en_US"
    }
  end

  def default_twitter_tags
    {
      card: "summary_large_image",
      site: "@ofie_platform"
    }
  end

  def site_name
    "Ofie"
  end
end
