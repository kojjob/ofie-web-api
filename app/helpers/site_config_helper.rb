module SiteConfigHelper
  # Load and cache site configuration
  def site_config
    @site_config ||= YAML.load_file(Rails.root.join('config', 'site_config.yml')).with_indifferent_access
  end

  # Company information helpers
  def company_name
    site_config.dig(:company, :name) || 'Ofie'
  end

  def company_tagline
    site_config.dig(:company, :tagline) || 'Your Dream Home Awaits'
  end

  def company_description
    site_config.dig(:company, :description) || 'Premium Real Estate Platform'
  end

  def company_full_description
    site_config.dig(:company, :full_description) || 'Discover luxury homes and properties with our premium platform.'
  end

  # Statistics helpers with dynamic data
  def total_families_count
    site_config.dig(:statistics, :total_families) || 25000
  end

  def platform_rating
    site_config.dig(:statistics, :rating) || 4.9
  end

  def monthly_joiners_count
    site_config.dig(:statistics, :monthly_joiners) || 12000
  end

  def verified_properties_count
    site_config.dig(:statistics, :verified_properties) || 50000
  end

  def growth_rate_text
    site_config.dig(:statistics, :growth_rate) || '+18% this quarter'
  end

  def search_time_text
    site_config.dig(:statistics, :search_time) || '< 3 seconds'
  end

  # Dynamic statistics with fallbacks
  def total_properties_stat
    @total_properties || site_config.dig(:statistics, :fallbacks, :total_properties) || 50000
  end

  def available_properties_stat
    @available_properties || site_config.dig(:statistics, :fallbacks, :available_properties) || 12500
  end

  def total_users_stat
    @total_users || site_config.dig(:statistics, :fallbacks, :total_users) || 25000
  end

  def cities_count_stat
    @cities_count || site_config.dig(:statistics, :fallbacks, :cities_count) || 150
  end

  # Search form helpers
  def property_type_options
    options = site_config.dig(:search, :property_types) || []
    options.map { |option| [option[:label], option[:value]] }
  end

  def bedroom_options
    options = site_config.dig(:search, :bedroom_options) || []
    options.map { |option| [option[:label], option[:value]] }
  end

  def min_price_placeholder
    site_config.dig(:search, :price_placeholders, :min) || '$300,000'
  end

  def max_price_placeholder
    site_config.dig(:search, :price_placeholders, :max) || '$800,000'
  end

  # Trust indicators
  def trust_badges
    site_config.dig(:trust, :badges) || []
  end

  # Features section
  def features_section_title
    site_config.dig(:features, :section_title) || 'Experience the Difference'
  end

  def features_section_description
    site_config.dig(:features, :section_description) || 'We redefine the real estate experience with cutting-edge technology.'
  end

  def feature_items
    site_config.dig(:features, :items) || []
  end

  # Hero section
  def hero_title_line_1
    site_config.dig(:hero, :title_line_1) || 'Find Your'
  end

  def hero_title_line_2
    site_config.dig(:hero, :title_line_2) || 'Perfect Home'
  end

  def hero_subtitle
    site_config.dig(:hero, :subtitle) || 'Where luxury meets simplicity'
  end

  def hero_description
    site_config.dig(:hero, :description) || 'Discover curated properties with our intelligent search platform.'
  end

  def hero_features
    site_config.dig(:hero, :features) || ['Premium listings', 'Instant matches', 'Verified quality']
  end

  # CTA section
  def cta_title_line_1
    site_config.dig(:cta, :title_line_1) || 'Your Dream Home'
  end

  def cta_title_line_2
    site_config.dig(:cta, :title_line_2) || 'Awaits You'
  end

  def cta_description
    site_config.dig(:cta, :description) || 'Join thousands of satisfied homeowners.'
  end

  def cta_highlights
    site_config.dig(:cta, :highlights) || []
  end

  def cta_trust_indicators
    site_config.dig(:cta, :trust_indicators) || []
  end

  # Marketing messages
  def search_benefits
    site_config.dig(:marketing, :search_benefits) || ['✓ Free to use', '✓ Instant results', '✓ No registration']
  end

  def property_section_badge
    site_config.dig(:marketing, :property_section, :badge) || 'Premium Collection'
  end

  def property_section_title_line_1
    site_config.dig(:marketing, :property_section, :title_line_1) || 'Featured'
  end

  def property_section_title_line_2
    site_config.dig(:marketing, :property_section, :title_line_2) || 'Properties'
  end

  def property_section_description
    site_config.dig(:marketing, :property_section, :description) || 'Handpicked luxury homes'
  end

  def property_section_live_update
    site_config.dig(:marketing, :property_section, :live_update) || 'New properties added daily'
  end

  def no_properties_title
    site_config.dig(:marketing, :property_section, :no_properties, :title) || 'New Properties Coming Soon!'
  end

  def no_properties_description
    site_config.dig(:marketing, :property_section, :no_properties, :description) || 'We\'re curating the best properties just for you.'
  end

  def no_properties_button_text
    site_config.dig(:marketing, :property_section, :no_properties, :button_text) || 'Notify Me'
  end

  # SEO helpers
  def seo_title
    site_config.dig(:seo, :title) || "#{company_name} - #{company_tagline} | #{company_description}"
  end

  def seo_description
    site_config.dig(:seo, :description) || company_full_description
  end

  def seo_keywords
    site_config.dig(:seo, :keywords) || 'real estate, homes for sale, apartments, luxury properties'
  end

  # Utility methods
  def format_number_with_suffix(number)
    return "#{number / 1000}K+" if number >= 1000
    number.to_s
  end

  def format_large_number(number)
    number_with_delimiter(number)
  end
end
