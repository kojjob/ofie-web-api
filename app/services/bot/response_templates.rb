# Enhanced Response Templates with Rich Content and Smart Suggestions
class Bot::ResponseTemplates
  class << self
    def get_template(intent, entities, context)
      case intent
      when :property_search_advanced
        property_search_template(entities, context)
      when :application_guidance
        application_guidance_template(entities, context)
      when :maintenance_intelligent
        maintenance_template(entities, context)
      when :financial_planning
        financial_planning_template(entities, context)
      when :neighborhood_info
        neighborhood_template(entities, context)
      when :legal_guidance
        legal_guidance_template(entities, context)
      when :market_insights
        market_insights_template(entities, context)
      when :lease_consultation
        lease_consultation_template(entities, context)
      else
        fallback_template(intent, entities, context)
      end
    end

    private

    def property_search_template(entities, context)
      response = "🏠 **Property Search Assistant**\n\n"

      if entities.any?
        response += "Based on your criteria:\n"
        entities.each do |key, value|
          response += format_search_criteria(key, value)
        end
        response += "\n"
      end

      response += "I'll help you find the perfect property! Here's what I can do:\n\n"
      response += "🔍 **Smart Search Features:**\n"
      response += "• Advanced filtering by location, price, amenities\n"
      response += "• AI-powered recommendations based on your preferences\n"
      response += "• Real-time availability updates\n"
      response += "• Virtual tour scheduling\n"
      response += "• Neighborhood safety and amenity scores\n\n"

      response += "💡 **Pro Tips:**\n"
      response += "• Save your searches to get instant alerts\n"
      response += "• Use the map view to explore different areas\n"
      response += "• Check out property reviews from previous tenants\n"
      response += "• Schedule multiple viewings for the same day\n\n"

      response += "What specific type of property are you looking for?"
    end

    def application_guidance_template(entities, context)
      user_stage = determine_application_stage(context)

      response = "📋 **Rental Application Guide**\n\n"

      case user_stage
      when :preparing
        response += "**Getting Ready to Apply:**\n\n"
        response += "📄 **Required Documents Checklist:**\n"
        response += "✅ Government-issued photo ID\n"
        response += "✅ Proof of income (last 3 pay stubs or employment letter)\n"
        response += "✅ Bank statements (last 2-3 months)\n"
        response += "✅ References (previous landlords, employers)\n"
        response += "✅ Credit report (optional - some landlords run their own)\n"
        response += "✅ Rental history and references\n\n"

        response += "💰 **Financial Requirements:**\n"
        response += "• Monthly income should be 2.5-3x the rent\n"
        response += "• Good credit score (typically 650+)\n"
        response += "• Security deposit (usually 1-2 months' rent)\n"
        response += "• First month's rent due at signing\n\n"

        response += "⚡ **Quick Application Tips:**\n"
        response += "• Apply within 24 hours of viewing\n"
        response += "• Be honest and complete in your application\n"
        response += "• Include a personal cover letter\n"
        response += "• Respond quickly to landlord requests\n"

      when :submitted
        response += "**Your Application is Under Review:**\n\n"
        response += "⏰ **Typical Timeline:**\n"
        response += "• Initial review: 1-3 business days\n"
        response += "• Background check: 2-5 business days\n"
        response += "• Final decision: 3-7 business days\n\n"

        response += "🔄 **What's Happening Now:**\n"
        response += "• Landlord reviewing your application\n"
        response += "• Income and employment verification\n"
        response += "• Credit and background checks\n"
        response += "• Reference contact and verification\n\n"

        response += "📞 **Stay Engaged:**\n"
        response += "• Respond promptly to any requests\n"
        response += "• Keep your phone accessible\n"
        response += "• Have additional documents ready\n"
        response += "• Follow up politely if no response after 5 days\n"

      when :approved
        response += "🎉 **Congratulations! Your Application was Approved!**\n\n"
        response += "🚀 **Next Steps:**\n"
        response += "1. **Review the lease agreement carefully**\n"
        response += "2. **Ask questions about any unclear terms**\n"
        response += "3. **Arrange lease signing appointment**\n"
        response += "4. **Prepare move-in funds**\n"
        response += "5. **Get renters insurance**\n"
        response += "6. **Schedule utilities connection**\n\n"

        response += "💰 **Move-in Costs to Prepare:**\n"
        response += "• Security deposit\n"
        response += "• First month's rent\n"
        response += "• Last month's rent (if required)\n"
        response += "• Application fee (if not paid already)\n"
        response += "• Utility deposits\n"
      end

      response
    end

    def maintenance_template(entities, context)
      urgency = entities[:urgency] || :normal
      category = entities[:maintenance_category] || "general"

      response = "🔧 **Maintenance Request Assistant**\n\n"

      if urgency == :emergency
        response += "🚨 **EMERGENCY PROTOCOL ACTIVATED**\n\n"
        response += "**Immediate Actions:**\n"
        response += "1. 📞 Call your landlord immediately\n"
        response += "2. 🆘 If safety risk, call emergency services (911)\n"
        response += "3. 📸 Document the issue with photos\n"
        response += "4. 🚰 Turn off water/gas if applicable\n"
        response += "5. 🏃‍♂️ Evacuate if necessary\n\n"

        response += "**Emergency Contacts:**\n"
        response += "• Landlord Emergency Line: [Will be filled from property]\n"
        response += "• Building Management: [Will be filled from property]\n"
        response += "• Local Emergency Services: 911\n\n"
      else
        response += "I'll help you create an effective maintenance request!\n\n"
      end

      response += "🛠️ **Maintenance Categories:**\n"
      BOT_MAINTENANCE_CATEGORIES.each do |cat, description|
        indicator = cat == category ? "👉 " : "• "
        response += "#{indicator}**#{cat.humanize}**: #{description}\n"
      end

      response += "\n📝 **Creating an Effective Request:**\n"
      response += "• **Be specific**: Describe exactly what's wrong\n"
      response += "• **Include location**: Which room/area is affected\n"
      response += "• **Add photos**: Visual evidence helps diagnosis\n"
      response += "• **Mention urgency**: Emergency, high, medium, or low\n"
      response += "• **Your availability**: When can repairs be done\n\n"

      response += "⏰ **Expected Response Times:**\n"
      response += "• **Emergency**: Immediate response\n"
      response += "• **High Priority**: Within 24 hours\n"
      response += "• **Medium Priority**: 2-3 business days\n"
      response += "• **Low Priority**: 1 week\n\n"

      unless urgency == :emergency
        response += "💡 **Prevention Tips for #{category.humanize}:**\n"
        response += get_prevention_tips(category)
      end

      response
    end

    def financial_planning_template(entities, context)
      budget = entities[:budget]
      income = entities[:income]

      response = "💰 **Rental Financial Planning**\n\n"

      if budget && income
        analysis = analyze_budget_feasibility(budget, income)
        response += format_budget_analysis(analysis)
      else
        response += "Let me help you plan your rental budget!\n\n"
      end

      response += "📊 **The 30% Rule:**\n"
      response += "Experts recommend spending no more than 30% of your gross monthly income on rent.\n\n"

      response += "💸 **Beyond Rent - Monthly Costs to Consider:**\n"
      response += "• **Utilities**: $100-200 (electric, gas, water, internet)\n"
      response += "• **Renters Insurance**: $15-30\n"
      response += "• **Parking**: $50-200 (if not included)\n"
      response += "• **Storage**: $50-100 (if needed)\n"
      response += "• **Maintenance Reserve**: $50-100 (for minor repairs)\n\n"

      response += "🏦 **Upfront Costs:**\n"
      response += "• **Security Deposit**: 1-2 months' rent\n"
      response += "• **First Month's Rent**: Full amount\n"
      response += "• **Last Month's Rent**: Sometimes required\n"
      response += "• **Application Fees**: $50-200 per application\n"
      response += "• **Moving Costs**: $500-2000\n"
      response += "• **Utility Deposits**: $100-300\n\n"

      response += "💡 **Money-Saving Tips:**\n"
      response += "• Look for utilities-included properties\n"
      response += "• Consider properties slightly outside city center\n"
      response += "• Apply to multiple properties quickly\n"
      response += "• Negotiate move-in incentives\n"
      response += "• Look for properties with amenities you'd pay for separately\n\n"

      response += "🎯 **Ready to calculate your budget?** Tell me your monthly income and I'll show you what rent range works best for you!"

      response
    end

    def neighborhood_template(entities, context)
      location = entities[:location]

      response = "🏘️ **Neighborhood Research Assistant**\n\n"

      if location
        response += "**Analyzing: #{location}**\n\n"
        response += "📍 **Location Insights:**\n"
        response += "[Location-specific data would be inserted here]\n\n"
      else
        response += "Which neighborhood would you like to explore?\n\n"
      end

      response += "🔍 **What I Can Tell You About Any Neighborhood:**\n\n"
      response += "🛡️ **Safety & Security:**\n"
      response += "• Crime statistics and trends\n"
      response += "• Police response times\n"
      response += "• Street lighting and safety features\n"
      response += "• Neighborhood watch programs\n\n"

      response += "🚌 **Transportation:**\n"
      response += "• Public transit accessibility\n"
      response += "• Commute times to major areas\n"
      response += "• Parking availability and costs\n"
      response += "• Bike lane infrastructure\n\n"

      response += "🏪 **Amenities & Services:**\n"
      response += "• Grocery stores and shopping\n"
      response += "• Restaurants and entertainment\n"
      response += "• Medical facilities and pharmacies\n"
      response += "• Parks and recreational areas\n\n"

      response += "🎓 **Education:**\n"
      response += "• School ratings and districts\n"
      response += "• Libraries and educational resources\n"
      response += "• Childcare and daycare options\n\n"

      response += "📈 **Market Trends:**\n"
      response += "• Average rental prices\n"
      response += "• Price trends over time\n"
      response += "• Vacancy rates\n"
      response += "• Future development plans\n\n"

      response += "🌟 **Community:**\n"
      response += "• Demographics and lifestyle\n"
      response += "• Community events and culture\n"
      response += "• Noise levels and atmosphere\n"
      response += "• Pet-friendliness\n\n"

      response += "Just tell me a neighborhood name or address, and I'll provide a comprehensive analysis!"

      response
    end

    def legal_guidance_template(entities, context)
      response = "⚖️ **Rental Legal Guidance**\n\n"
      response += "⚠️ **Important**: This is general information only. For specific legal advice, consult a qualified attorney.\n\n"

      response += "📋 **Tenant Rights Overview:**\n\n"
      response += "🏠 **Right to Habitable Living:**\n"
      response += "• Safe and sanitary conditions\n"
      response += "• Working plumbing, heating, and electrical\n"
      response += "• Proper locks and security measures\n"
      response += "• No significant health hazards\n\n"

      response += "🔒 **Privacy Rights:**\n"
      response += "• Landlord must give notice before entry (usually 24-48 hours)\n"
      response += "• Entry only for valid reasons (repairs, inspections, emergencies)\n"
      response += "• Right to quiet enjoyment of your home\n\n"

      response += "💰 **Financial Protections:**\n"
      response += "• Security deposit must be returned within specified timeframe\n"
      response += "• Limits on security deposit amounts\n"
      response += "• Right to receipts for deposit deductions\n"
      response += "• Protection against discriminatory pricing\n\n"

      response += "🚫 **Discrimination Protection:**\n"
      response += "Landlords cannot discriminate based on:\n"
      response += "• Race, color, national origin\n"
      response += "• Religion, sex, familial status\n"
      response += "• Disability\n"
      response += "• Other protected characteristics (varies by location)\n\n"

      response += "📄 **Lease Agreement Rights:**\n"
      response += "• Right to read and understand before signing\n"
      response += "• Protection against unfair lease terms\n"
      response += "• Right to copy of signed lease\n"
      response += "• Clear terms for lease termination\n\n"

      response += "🔧 **Maintenance & Repairs:**\n"
      response += "• Landlord responsible for major repairs\n"
      response += "• Right to request repairs in writing\n"
      response += "• Right to withhold rent in some cases (varies by state)\n"
      response += "• Right to make emergency repairs and deduct cost (in some areas)\n\n"

      response += "📞 **When to Seek Legal Help:**\n"
      response += "• Discrimination or harassment\n"
      response += "• Illegal eviction attempts\n"
      response += "• Unsafe living conditions ignored by landlord\n"
      response += "• Improper security deposit handling\n"
      response += "• Lease disputes or unclear terms\n\n"

      response += "🔗 **Resources:**\n"
      response += "• Local tenant rights organizations\n"
      response += "• Legal aid societies\n"
      response += "• State housing authorities\n"
      response += "• Tenant unions\n\n"

      response += "What specific legal question can I help you research?"

      response
    end

    def market_insights_template(entities, context)
      location = entities[:location]

      response = "📈 **Rental Market Insights**\n\n"

      if location
        response += "**Market Analysis for #{location}:**\n\n"
        response += "[Location-specific market data would be inserted here]\n\n"
      end

      response += "📊 **Current Market Trends:**\n\n"
      response += "🏙️ **Urban Markets:**\n"
      response += "• Increasing demand for flexible lease terms\n"
      response += "• Growing importance of home office spaces\n"
      response += "• Premium for buildings with amenities\n"
      response += "• Virtual touring becoming standard\n\n"

      response += "💰 **Pricing Trends:**\n"
      response += "• Average rent increases: 3-5% annually\n"
      response += "• Luxury segment growing faster\n"
      response += "• Concessions more common in competitive markets\n"
      response += "• Pet fees and amenity fees increasing\n\n"

      response += "🏠 **Property Features in Demand:**\n"
      response += "• In-unit laundry (high priority)\n"
      response += "• Dedicated parking spaces\n"
      response += "• Outdoor space (balcony, patio)\n"
      response += "• Modern kitchen appliances\n"
      response += "• High-speed internet capability\n"
      response += "• Storage space\n\n"

      response += "📍 **Location Factors:**\n"
      response += "• Proximity to public transportation\n"
      response += "• Walkability scores increasingly important\n"
      response += "• Safety and crime rates major factors\n"
      response += "• School districts (even for non-parents)\n"
      response += "• Access to green spaces\n\n"

      response += "📅 **Best Times to Search:**\n"
      response += "• **Peak Season**: May-September (most inventory)\n"
      response += "• **Off-Season**: November-February (better deals)\n"
      response += "• **Best Days**: Tuesday-Thursday (less competition)\n"
      response += "• **Best Times**: Morning applications often processed first\n\n"

      response += "💡 **Market Navigation Tips:**\n"
      response += "• Be prepared to move quickly in hot markets\n"
      response += "• Have all documents ready before viewing\n"
      response += "• Consider slightly longer commutes for better value\n"
      response += "• Look for emerging neighborhoods\n"
      response += "• Factor in total cost of living, not just rent\n\n"

      response += "Want specific market data for a particular area? Just let me know the location!"

      response
    end

    def lease_consultation_template(entities, context)
      response = "📄 **Lease Agreement Consultation**\n\n"

      response += "🔍 **Key Lease Terms to Review:**\n\n"
      response += "💰 **Financial Terms:**\n"
      response += "• **Monthly rent amount** and due date\n"
      response += "• **Security deposit** amount and return conditions\n"
      response += "• **Late fees** and grace period\n"
      response += "• **Utilities** - what's included vs. your responsibility\n"
      response += "• **Pet deposits/fees** if applicable\n"
      response += "• **Parking fees** if separate\n\n"

      response += "⏰ **Lease Duration & Renewal:**\n"
      response += "• **Start and end dates**\n"
      response += "• **Renewal terms** and rent increase policies\n"
      response += "• **Early termination** clause and penalties\n"
      response += "• **Month-to-month** conversion options\n"
      response += "• **Notice periods** for moving out\n\n"

      response += "🏠 **Property Use & Restrictions:**\n"
      response += "• **Occupancy limits** (who can live there)\n"
      response += "• **Pet policy** (types, sizes, restrictions)\n"
      response += "• **Smoking policy**\n"
      response += "• **Noise restrictions** and quiet hours\n"
      response += "• **Subletting/Airbnb** policies\n"
      response += "• **Parking rules** and guest parking\n\n"

      response += "🔧 **Maintenance & Repairs:**\n"
      response += "• **Landlord responsibilities** vs. **tenant responsibilities**\n"
      response += "• **Emergency contact** information\n"
      response += "• **Repair request** procedures\n"
      response += "• **Property condition** at move-in\n"
      response += "• **Normal wear and tear** vs. damage\n\n"

      response += "🔒 **Rights & Responsibilities:**\n"
      response += "• **Entry notice** requirements (usually 24-48 hours)\n"
      response += "• **Privacy rights** and landlord access\n"
      response += "• **Property modifications** allowed/prohibited\n"
      response += "• **Insurance requirements** (renters insurance)\n"
      response += "• **Move-out conditions** and cleaning requirements\n\n"

      response += "⚠️ **Red Flags to Watch For:**\n"
      response += "• Unreasonable late fees or penalties\n"
      response += "• Excessive restrictions on normal living\n"
      response += "• Vague language about responsibilities\n"
      response += "• No mention of security deposit return process\n"
      response += "• Automatic renewal without notice\n"
      response += "• Waiver of your legal rights\n\n"

      response += "❓ **Questions to Ask Before Signing:**\n"
      response += "• Can I see the actual unit I'll be renting?\n"
      response += "• What happens if I need to break the lease early?\n"
      response += "• How are maintenance requests handled?\n"
      response += "• What's included in the rent?\n"
      response += "• Are there any planned rent increases?\n"
      response += "• What's the process for getting my security deposit back?\n\n"

      response += "📝 **Before You Sign:**\n"
      response += "• Read every word carefully\n"
      response += "• Ask questions about anything unclear\n"
      response += "• Take photos/notes of the property condition\n"
      response += "• Keep a copy of the signed lease\n"
      response += "• Make sure all promises are in writing\n\n"

      response += "Have questions about a specific lease term? I'm here to help explain!"

      response
    end

    def fallback_template(intent, entities, context)
      "I understand you're asking about #{intent.to_s.humanize.downcase}, but I need a bit more information to help you effectively. Could you please provide more details about what specifically you'd like to know?"
    end

    # Helper methods
    def format_search_criteria(key, value)
      case key
      when :bedroom_count
        "• 🛏️ #{value} bedroom#{value > 1 ? 's' : ''}\n"
      when :bathroom_count
        "• 🚿 #{value} bathroom#{value > 1 ? 's' : ''}\n"
      when :budget
        "• 💰 Budget: $#{value}\n"
      when :location
        "• 📍 Location: #{value}\n"
      when :property_type
        "• 🏠 Type: #{value.humanize}\n"
      when :amenities
        "• ✨ Amenities: #{Array(value).join(', ')}\n"
      else
        "• #{key.to_s.humanize}: #{value}\n"
      end
    end

    def determine_application_stage(context)
      # This would analyze user context to determine their stage
      :preparing # Default
    end

    def analyze_budget_feasibility(budget, income)
      ratio = budget.to_f / income.to_f

      {
        ratio: ratio,
        recommendation: case ratio
                        when 0..0.25
            :very_safe
                        when 0.25..0.30
            :safe
                        when 0.30..0.35
            :moderate
                        when 0.35..0.50
            :high_risk
                        else
            :too_high
                        end
      }
    end

    def format_budget_analysis(analysis)
      ratio_percent = (analysis[:ratio] * 100).round(1)

      response = "**Your Budget Analysis:**\n\n"
      response += "💡 **Rent-to-Income Ratio**: #{ratio_percent}%\n\n"

      case analysis[:recommendation]
      when :very_safe
        response += "✅ **Excellent!** Your housing costs are well within the recommended range. You'll have plenty of room for other expenses and savings.\n\n"
      when :safe
        response += "✅ **Great!** You're within the ideal 25-30% range. This leaves room for other important expenses.\n\n"
      when :moderate
        response += "⚠️ **Acceptable** but at the higher end. Make sure you budget carefully for other expenses.\n\n"
      when :high_risk
        response += "⚠️ **High risk** - this might strain your budget. Consider looking for lower-cost options or increasing your income.\n\n"
      when :too_high
        response += "❌ **Too high** - this budget is likely unsustainable. I'd recommend looking for more affordable options.\n\n"
      end

      response
    end

    def get_prevention_tips(category)
      tips = {
        "plumbing" => "• Don't flush anything other than toilet paper\n• Clean drains regularly\n• Report leaks immediately\n• Don't use chemical drain cleaners",
        "electrical" => "• Don't overload outlets\n• Use surge protectors\n• Replace burnt-out bulbs promptly\n• Report flickering lights",
        "hvac" => "• Change filters regularly\n• Keep vents unblocked\n• Set reasonable temperatures\n• Schedule annual maintenance",
        "appliances" => "• Clean refrigerator coils\n• Don't overload washing machines\n• Clean lint traps\n• Use appliances as intended"
      }

      tips[category] || "• Regular maintenance and prompt reporting of issues\n• Follow manufacturer guidelines\n• Keep areas clean and uncluttered"
    end

    # Constants for maintenance categories
    BOT_MAINTENANCE_CATEGORIES = {
      "plumbing" => "Leaks, clogs, water pressure issues, toilet problems",
      "electrical" => "Power outages, faulty outlets, lighting issues",
      "hvac" => "Heating, cooling, ventilation problems",
      "appliances" => "Refrigerator, stove, washer, dryer issues",
      "structural" => "Doors, windows, walls, flooring problems",
      "pest_control" => "Insects, rodents, or other pest issues",
      "safety" => "Smoke detectors, locks, security concerns",
      "other" => "Any other maintenance needs"
    }.freeze
  end
end
