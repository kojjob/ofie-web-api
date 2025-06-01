module ApplicationHelper
  # Determine if the bot widget should be shown on the current page
  def show_bot_widget?
    # Show bot on main pages where users might need help
    return true if controller_name == "home" && action_name == "index"
    return true if controller_name == "properties"
    return true if controller_name == "home" && %w[about contact help].include?(action_name)
    return true if controller_name == "rental_applications"
    return true if controller_name == "property_viewings"
    return true if controller_name == "conversations"

    # Don't show on authentication pages, admin pages, or API endpoints
    return false if controller_name == "auth"
    return false if controller_name.start_with?("admin")
    return false if request.path.start_with?("/api/")

    # Show on dashboard for logged-in users
    return true if user_signed_in? && controller_name == "dashboard"

    # Default to not showing the bot
    false
  end

  # Page title helper
  def page_title(title = nil)
    base_title = "Ofie - Premium Property Rental Platform"
    if title.present?
      "#{title} | #{base_title}"
    else
      base_title
    end
  end

  # Meta description helper
  def meta_description(description = nil)
    default_description = "Find your perfect rental property with Ofie. Browse thousands of verified listings, apply online, and manage your rental journey with our comprehensive platform."
    description.present? ? description : default_description
  end

  # Check if user is signed in (compatibility method)
  def user_signed_in?
    current_user.present?
  end

  # Format currency
  def format_currency(amount)
    number_to_currency(amount, precision: 0)
  end

  # Format date
  def format_date(date, format = :long)
    return "" unless date
    date.strftime(
      case format
      when :short
        "%m/%d/%Y"
      when :medium
        "%b %d, %Y"
      when :long
        "%B %d, %Y"
      else
        "%B %d, %Y at %I:%M %p"
      end
    )
  end

  # Active link helper
  def active_link_class(path, exact_match: false)
    if exact_match
      current_page?(path) ? "active" : ""
    else
      request.path.start_with?(path) ? "active" : ""
    end
  end

  # Truncate text with proper word boundaries
  def smart_truncate(text, length = 150)
    return "" unless text
    return text if text.length <= length

    truncated = text[0, length]
    # Find the last space to avoid cutting words
    last_space = truncated.rindex(" ")
    if last_space
      truncated = truncated[0, last_space]
    end
    "#{truncated}..."
  end
end
