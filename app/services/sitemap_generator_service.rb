# Service to generate XML sitemap for SEO
class SitemapGeneratorService
  include Rails.application.routes.url_helpers
  
  def initialize(host = nil)
    @host = host || Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000'
    @protocol = Rails.env.production? ? 'https' : 'http'
  end
  
  def generate
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                 'xmlns:image' => 'http://www.google.com/schemas/sitemap-image/1.1',
                 'xmlns:video' => 'http://www.google.com/schemas/sitemap-video/1.1') do
        
        # Static pages with high priority
        add_static_pages(xml)
        
        # Dynamic content pages
        add_property_pages(xml)
        add_category_pages(xml)
        add_user_pages(xml)
        add_help_pages(xml)
      end
    end
    
    builder.to_xml
  end
  
  private
  
  def add_static_pages(xml)
    # Homepage - highest priority
    add_url(xml, root_url(host: @host, protocol: @protocol), {
      lastmod: Date.today.iso8601,
      changefreq: 'daily',
      priority: 1.0
    })
    
    # Main static pages
    static_pages = [
      { path: about_url(host: @host, protocol: @protocol), priority: 0.8, changefreq: 'weekly' },
      { path: contact_url(host: @host, protocol: @protocol), priority: 0.7, changefreq: 'monthly' },
      { path: help_url(host: @host, protocol: @protocol), priority: 0.6, changefreq: 'weekly' },
      { path: tenant_screening_url(host: @host, protocol: @protocol), priority: 0.7, changefreq: 'weekly' },
      { path: landlord_tools_url(host: @host, protocol: @protocol), priority: 0.7, changefreq: 'weekly' },
      { path: market_analysis_url(host: @host, protocol: @protocol), priority: 0.6, changefreq: 'weekly' },
      { path: calculators_url(host: @host, protocol: @protocol), priority: 0.6, changefreq: 'monthly' },
      { path: cookie_policy_url(host: @host, protocol: @protocol), priority: 0.3, changefreq: 'yearly' }
    ]
    
    static_pages.each do |page|
      add_url(xml, page[:path], {
        lastmod: Date.today.iso8601,
        changefreq: page[:changefreq],
        priority: page[:priority]
      })
    end
  end
  
  def add_property_pages(xml)
    # Properties index page
    add_url(xml, properties_url(host: @host, protocol: @protocol), {
      lastmod: Date.today.iso8601,
      changefreq: 'daily',
      priority: 0.9
    })
    
    # Individual property pages
    Property.published.includes(:images_attachments).find_each do |property|
      images = property.images.map do |image|
        {
          loc: rails_blob_url(image, host: @host, protocol: @protocol),
          caption: property.title,
          title: property.title
        }
      end if property.images.attached?
      
      add_url(xml, property_url(property, host: @host, protocol: @protocol), {
        lastmod: property.updated_at.iso8601,
        changefreq: property_changefreq(property),
        priority: property_priority(property),
        images: images || []
      })
    end
  end
  
  def add_category_pages(xml)
    # Add category/filter pages if you have them
    categories = ['apartment', 'house', 'condo', 'townhouse', 'studio']
    
    categories.each do |category|
      add_url(xml, properties_url(property_type: category, host: @host, protocol: @protocol), {
        lastmod: Date.today.iso8601,
        changefreq: 'daily',
        priority: 0.7
      })
    end
    
    # Add city-specific pages
    cities = Property.published.distinct.pluck(:city).compact
    cities.each do |city|
      add_url(xml, properties_url(city: city, host: @host, protocol: @protocol), {
        lastmod: Date.today.iso8601,
        changefreq: 'daily',
        priority: 0.7
      })
    end
  end
  
  def add_user_pages(xml)
    # Public user profiles (if applicable)
    User.where(public_profile: true).find_each do |user|
      add_url(xml, user_url(user, host: @host, protocol: @protocol), {
        lastmod: user.updated_at.iso8601,
        changefreq: 'weekly',
        priority: 0.5
      })
    end if User.column_names.include?('public_profile')
  end
  
  def add_help_pages(xml)
    # FAQ pages, guides, etc.
    help_sections = [
      { path: faq_url(host: @host, protocol: @protocol), priority: 0.6 },
      { path: rental_guide_url(host: @host, protocol: @protocol), priority: 0.6 },
      { path: landlord_guide_url(host: @host, protocol: @protocol), priority: 0.6 }
    ] rescue []
    
    help_sections.each do |section|
      add_url(xml, section[:path], {
        lastmod: Date.today.iso8601,
        changefreq: 'monthly',
        priority: section[:priority]
      })
    end
  end
  
  def add_url(xml, loc, options = {})
    xml.url do
      xml.loc loc
      xml.lastmod options[:lastmod] if options[:lastmod]
      xml.changefreq options[:changefreq] if options[:changefreq]
      xml.priority options[:priority] if options[:priority]
      
      # Add image sitemap data if present
      if options[:images].present?
        options[:images].each do |image|
          xml['image'].image do
            xml['image'].loc image[:loc]
            xml['image'].caption image[:caption] if image[:caption]
            xml['image'].title image[:title] if image[:title]
          end
        end
      end
    end
  end
  
  def property_changefreq(property)
    # More recent properties change more frequently
    days_old = (Date.today - property.created_at.to_date).to_i
    
    case days_old
    when 0..7
      'daily'
    when 8..30
      'weekly'
    when 31..90
      'monthly'
    else
      'yearly'
    end
  end
  
  def property_priority(property)
    # Featured or premium properties get higher priority
    base_priority = 0.8
    
    # Adjust based on property attributes
    base_priority += 0.1 if property.featured?
    base_priority -= 0.1 if property.created_at < 6.months.ago
    base_priority -= 0.1 unless property.available?
    
    [base_priority, 0.3].max # Minimum priority of 0.3
  end
end