class ToolsController < ApplicationController
  # Skip authentication for public tools
  skip_before_action :authenticate_request, only: [ :calculators, :market_analysis, :landlord_tools ]

  def calculators
    @page_title = "Rental Calculators"
    @page_description = "Calculate rental yields, mortgage payments, and property investment returns with our comprehensive tools."
  end

  def market_analysis
    @page_title = "Market Analysis"
    @page_description = "Get insights into local rental markets, property values, and investment opportunities."
  end

  def landlord_tools
    @page_title = "Landlord Tools"
    @page_description = "Essential tools and resources for property management and landlord success."
  end
end
