# 🏢 Comprehensive Real Estate Marketing Software Platform

## Executive Summary

A full-featured, enterprise-grade real estate marketing software platform designed to streamline property promotion, lead generation, client relationship management, and transaction processing for real estate agencies, brokerages, and property marketing professionals.

---

## Table of Contents

1. [Platform Overview](#platform-overview)
2. [Core Features](#core-features)
3. [Domain Models & Database Schema](#domain-models--database-schema)
4. [Business Logic & Workflows](#business-logic--workflows)
5. [Marketing Automation Engine](#marketing-automation-engine)
6. [Lead Management System](#lead-management-system)
7. [CRM & Client Portal](#crm--client-portal)
8. [Transaction Management](#transaction-management)
9. [Analytics & Reporting](#analytics--reporting)
10. [API & Integration Layer](#api--integration-layer)
11. [Technical Architecture](#technical-architecture)
12. [Implementation Roadmap](#implementation-roadmap)

---

## Platform Overview

### Vision
Empower real estate professionals with cutting-edge marketing technology to maximize property visibility, capture qualified leads, nurture client relationships, and close deals faster through intelligent automation and data-driven insights.

### Key Value Propositions
- **360° Marketing Automation**: Multi-channel property promotion across 100+ platforms
- **Intelligent Lead Capture**: AI-powered lead qualification and smart routing
- **Unified CRM**: Complete client lifecycle management from prospect to closing
- **Transaction Management**: End-to-end deal coordination with milestone tracking
- **Performance Analytics**: Real-time insights and predictive analytics
- **White-Label Platform**: Fully branded experience for agencies and brokerages

### Target Markets
- **Real Estate Agencies**: Independent brokerages and franchise operations
- **Property Management Companies**: Residential and commercial property managers
- **Real Estate Teams**: High-performing agent teams requiring collaboration tools
- **Individual Agents**: Solo practitioners needing professional marketing tools
- **Real Estate Developers**: New construction marketing and sales

---

## Core Features

### 1. Property Marketing Suite

#### Digital Listing Management
```yaml
Features:
  Multi-Channel Distribution:
    - Automatic syndication to 100+ property portals (Zillow, Realtor.com, Trulia, etc.)
    - MLS integration and synchronization
    - Social media auto-posting (Facebook, Instagram, LinkedIn)
    - Google My Business listings
    - Custom website integration via API/widget
    - Real-time listing status synchronization

  SEO Optimization:
    - Auto-generated meta tags and descriptions
    - Schema.org structured data markup
    - Sitemap generation for search engines
    - Keyword optimization recommendations
    - Friendly URL slugs
    - Local SEO optimization

  Rich Media Management:
    - Professional photo galleries with lightbox viewing
    - 360° virtual tour integration (Matterport, iGuide)
    - HD video walkthroughs and drone footage
    - Interactive floor plans with room measurements
    - 3D renderings and staging
    - Neighborhood and amenity photos

  Content Generation:
    - AI-powered property descriptions
    - Multilingual listing translation
    - Automatic feature extraction
    - Comparable property analysis
    - Market statistics integration
    - Neighborhood description generation

  Listing Enhancement:
    - Featured listing promotion
    - Spotlight banners and badges
    - Social proof (views, inquiries, saves)
    - Urgency indicators (pending, price reduced)
    - Open house calendars
    - Virtual showing scheduling
```

#### Marketing Campaign Tools
```yaml
Email Marketing:
  Campaign Types:
    - Property alert campaigns (new listings, price changes)
    - Drip nurture sequences
    - Newsletter broadcasts
    - Event invitations (open houses)
    - Market update reports
    - Client anniversary emails

  Features:
    - Drag-and-drop email builder
    - 200+ professional templates
    - Dynamic property insertion
    - Personalization tokens (name, preferences, behavior)
    - A/B testing (subject lines, content, send times)
    - Deliverability optimization
    - Unsubscribe management
    - GDPR compliance tools

Social Media Automation:
  Platforms:
    - Facebook (posts, stories, marketplace)
    - Instagram (feed, stories, reels)
    - LinkedIn (posts, articles)
    - Twitter (tweets, threads)
    - Pinterest (pins, boards)
    - YouTube (video uploads)

  Features:
    - Content calendar with visual scheduling
    - Auto-generated property showcase posts
    - Hashtag strategy recommendations
    - Best time to post suggestions
    - Social listening and engagement tracking
    - Influencer collaboration management
    - Paid social ad integration

Paid Advertising:
  Google Ads:
    - Search campaign creation
    - Display network ads
    - YouTube video ads
    - Local service ads
    - Smart bidding strategies
    - Keyword research tools
    - Conversion tracking

  Facebook/Instagram Ads:
    - Dynamic property ads
    - Carousel ad creation
    - Lead generation forms
    - Lookalike audience targeting
    - Retargeting campaigns
    - A/B creative testing
    - ROI tracking

  Display Advertising:
    - Programmatic ad buying
    - Retargeting pixel implementation
    - Banner ad creation
    - Native advertising
    - Video ad campaigns

Print Marketing:
  Materials:
    - Property flyer generator
    - Brochure designer
    - Postcard templates
    - "Just Listed/Sold" signs
    - Door hangers
    - Business cards

  Features:
    - Professional design templates
    - Brand consistency enforcement
    - High-resolution PDF export
    - Print vendor integration
    - Direct mail campaign management
    - QR code generation for tracking
```

#### Landing Page Builder
```yaml
Page Builder:
  Features:
    - Drag-and-drop visual editor
    - No coding required
    - Mobile-responsive design
    - Real-time preview
    - Version history
    - Template cloning

  Elements:
    - Property showcase sections
    - Lead capture forms
    - Photo/video galleries
    - Testimonial displays
    - Agent bio sections
    - Call-to-action buttons
    - Countdown timers
    - Social proof widgets
    - Map integration
    - Contact information

  Templates:
    - Single property showcase
    - Neighborhood guide pages
    - Open house landing pages
    - "Coming Soon" teasers
    - Thank you pages
    - Property comparison pages
    - Market report pages

  Optimization:
    - A/B testing framework
    - Heatmap analytics
    - Conversion tracking
    - Form analytics
    - SEO optimization
    - Load speed optimization
    - Custom domain mapping
```

#### Open House Management
```yaml
Event Management:
  Scheduling:
    - Calendar integration
    - Multiple date/time slots
    - Recurring events
    - Timezone handling
    - Availability checking
    - Agent assignment

  Registration:
    - Online pre-registration
    - QR code check-in
    - Digital sign-in sheets
    - Lead capture forms
    - ID verification (optional)
    - NDA collection

  Communication:
    - Event invitation emails
    - SMS reminders
    - Confirmation notifications
    - Directions and parking info
    - Last-minute updates
    - Post-event follow-ups

  On-Site Tools:
    - Mobile app check-in
    - Visitor tracking
    - Digital brochures
    - Instant inquiry capture
    - Photo sharing
    - Feedback collection

  Analytics:
    - Attendance tracking
    - Visitor demographics
    - Engagement metrics
    - Conversion tracking
    - Heat mapping (property areas)
    - Follow-up effectiveness
```

### 2. Lead Generation & Capture

#### Multi-Channel Lead Capture
```yaml
Website Integration:
  Forms:
    - Contact forms
    - Property inquiry forms
    - Schedule showing requests
    - Newsletter signup
    - Home valuation requests
    - Mortgage pre-qualification

  Interactive Elements:
    - Live chat widget
    - AI chatbot (24/7 availability)
    - Click-to-call buttons
    - Click-to-text (SMS)
    - Property favorites/save
    - Property comparison tool

  Engagement Triggers:
    - Exit-intent popups
    - Scroll-based forms
    - Time-delayed offers
    - Smart popups (behavior-based)
    - Content upgrade offers

Property Portal Integration:
  Platforms:
    - Zillow Premier Agent
    - Realtor.com
    - Trulia
    - Homes.com
    - Apartments.com
    - Redfin

  Features:
    - Real-time lead import
    - Lead deduplication
    - Response time tracking
    - Portal ROI analytics
    - Automated responses

Social Media Lead Capture:
  Facebook Lead Ads:
    - Pre-filled form integration
    - Instant lead sync
    - Custom questions
    - Privacy compliance
    - Thank you message automation

  Instagram Lead Forms:
    - Story swipe-up forms
    - Direct message automation
    - Comment-to-DM automation
    - Profile link tracking

  LinkedIn Lead Gen:
    - Sponsored content forms
    - InMail campaigns
    - Profile data pre-fill
    - Professional targeting

Offline Lead Capture:
  Methods:
    - Open house sign-in (tablet/mobile)
    - Business card scanning (OCR)
    - Phone call tracking (dynamic numbers)
    - Text-to-join keywords
    - QR code scanning
    - Voice assistant integration

  Features:
    - Automatic data entry
    - Duplicate detection
    - Source attribution
    - Instant CRM sync
    - Follow-up automation
```

#### Lead Qualification Engine
```yaml
AI Lead Scoring:
  Scoring Factors:
    Demographic (20%):
      - Budget alignment
      - Geographic location
      - Timeline urgency
      - Financing status
      - First-time buyer status

    Behavioral (40%):
      - Property views
      - Email engagement
      - Website visits
      - Search patterns
      - Inquiry quality
      - Response time

    Engagement (25%):
      - Communication frequency
      - Multi-channel activity
      - Content downloads
      - Event attendance
      - Showing requests

    Intent Signals (15%):
      - Specific property interest
      - Price point browsing
      - Mortgage calculator usage
      - Neighborhood research
      - School district research

  Scoring Algorithm:
    base_score = 0

    # Demographic factors
    if budget_in_range:
        base_score += 10
    if location_in_service_area:
        base_score += 10
    if pre_approved:
        base_score += 15
    if cash_buyer:
        base_score += 20

    # Behavioral factors
    base_score += property_views * 2 (max 10)
    base_score += email_opens * 1 (max 10)
    base_score += email_clicks * 3 (max 15)
    base_score += website_visits * 1 (max 5)

    # Engagement factors
    if inquiry_submitted:
        base_score += 10
    if showing_scheduled:
        base_score += 15
    if phone_call_made:
        base_score += 10

    # Intent signals
    if saved_properties > 0:
        base_score += 5
    if used_mortgage_calculator:
        base_score += 5
    if downloaded_resources:
        base_score += 5

    # Time decay
    days_since_last_activity = (today - last_activity_date).days
    decay_factor = max(0.5, 1 - (days_since_last_activity * 0.01))
    final_score = base_score * decay_factor

    return min(100, final_score)

  Classification:
    Hot Lead (90-100 points):
      - Immediate agent assignment
      - Priority follow-up (within 5 minutes)
      - SMS + email notification
      - Fast-track nurture sequence

    Warm Lead (70-89 points):
      - Standard agent assignment
      - Follow-up within 1 hour
      - Active nurture campaign
      - Weekly check-ins

    Cold Lead (50-69 points):
      - Team assignment or round-robin
      - Follow-up within 24 hours
      - Long-term nurture campaign
      - Monthly touchpoints

    Unqualified (<50 points):
      - Marketing-only touches
      - Quarterly check-ins
      - Re-engagement campaigns
      - Possible disqualification

Buyer Intent Analysis:
  Signals:
    High Intent:
      - Multiple showings scheduled
      - Mortgage pre-approval obtained
      - Specific property repeated views
      - Neighborhood deep research
      - School district investigation
      - Commute time calculations

    Medium Intent:
      - Property browsing patterns
      - Price range narrowing
      - Email engagement
      - General inquiry submission
      - Newsletter subscription

    Low Intent:
      - Passive browsing
      - Single property view
      - No engagement with content
      - Broad search criteria
      - No communication initiated

Budget Qualification:
  Verification Methods:
    - Pre-approval letter upload
    - Lender contact information
    - Current housing situation
    - Down payment readiness
    - Debt-to-income estimation
    - Employment verification

  Classification:
    Verified Buyer:
      - Pre-approval letter on file
      - Lender contact confirmed
      - Down payment funds verified

    Likely Qualified:
      - Budget stated and reasonable
      - Employment confirmed
      - Credit discussed

    Needs Qualification:
      - Budget unclear
      - Financing status unknown
      - First conversation needed

Timeline Prediction:
  Urgency Levels:
    Immediate (0-30 days):
      - Lease ending soon
      - Job relocation
      - Family emergency
      - Already sold current home

    Near-term (1-3 months):
      - Active search phase
      - Pre-approved and looking
      - School year planning

    Mid-term (3-6 months):
      - Getting finances ready
      - Market research phase
      - Exploratory stage

    Long-term (6-12 months):
      - Future planning
      - Market watching
      - Credit building

    Uncertain (12+ months):
      - Dream home shopping
      - Investment research
      - Market education
```

#### Lead Routing & Distribution
```yaml
Routing Engine:
  Routing Methods:
    Round-Robin:
      - Fair distribution across team
      - Skip unavailable agents
      - Rotation tracking
      - Load balancing

    Skill-Based:
      - Match to agent expertise
      - Property type specialization
      - Price point alignment
      - Language matching
      - Market area knowledge

    Geographic:
      - ZIP code assignment
      - City/neighborhood territories
      - Radius-based routing
      - Travel time consideration

    Performance-Based:
      - Prioritize top performers
      - Response time weighting
      - Conversion rate consideration
      - Client satisfaction scores
      - Activity level weighting

    Availability-Based:
      - Online status checking
      - Working hours verification
      - Vacation/OOO respect
      - Current workload assessment
      - Capacity limits

    VIP Routing:
      - Referral priority routing
      - High-value lead assignment
      - Repeat client routing
      - Brand partner leads

  Routing Rules:
    Conditions:
      - Lead source
      - Lead score/quality
      - Property type
      - Price range
      - Geographic location
      - Time of day
      - Day of week
      - Agent specialization
      - Current agent capacity

    Actions:
      - Assign to specific agent
      - Assign to team
      - Create task
      - Send notification
      - Trigger automation
      - Escalate if no response

  Assignment Logic:
    # Priority 1: Check for existing relationship
    if lead.has_previous_agent:
        assign_to(lead.previous_agent)
        return

    # Priority 2: Geographic territory
    if agency.geographic_routing_enabled:
        agent = find_agent_by_territory(lead.location)
        if agent and agent.available:
            assign_to(agent)
            return

    # Priority 3: Specialization match
    if lead.luxury_property and luxury_agents.any?:
        agent = find_available_luxury_agent()
        assign_to(agent)
        return

    # Priority 4: Language preference
    if lead.preferred_language != 'english':
        agent = find_agent_by_language(lead.preferred_language)
        if agent:
            assign_to(agent)
            return

    # Priority 5: Performance-based
    if agency.performance_routing_enabled:
        agent = find_top_performer_with_capacity()
        assign_to(agent)
        return

    # Priority 6: Round-robin (default)
    agent = next_agent_in_rotation()
    assign_to(agent)

  Agent Capacity Management:
    Capacity Scoring:
      max_capacity = agent.max_active_clients
      current_load = agent.current_active_clients
      capacity_ratio = current_load / max_capacity

      availability_hours = agent.hours_available_this_week
      availability_ratio = availability_hours / 40

      response_performance = agent.avg_response_time <= 15.minutes ? 1.0 : 0.5

      capacity_score = (
        (1 - capacity_ratio) * 0.4 +
        availability_ratio * 0.3 +
        response_performance * 0.3
      )

      return capacity_score

    Assignment Decision:
      if capacity_score > 0.7:
          assign_immediately()
      elif capacity_score > 0.4:
          assign_with_warning()
      else:
          overflow_to_team_lead()

  Notifications:
    Agent Notifications:
      - Email alert
      - SMS notification
      - Mobile app push
      - Desktop notification
      - Slack/Teams message

    Manager Notifications:
      - High-value lead alerts
      - Unassigned lead warnings
      - Agent capacity alerts
      - Response time violations

    Lead Notifications:
      - Assignment confirmation
      - Agent introduction email
      - Expected response timeframe
      - Direct contact information
```

### 3. CRM & Client Management

#### Contact Management
```yaml
Unified Contact Database:
  Core Information:
    Personal Details:
      - Full name (first, middle, last, suffix)
      - Email address (primary, secondary)
      - Phone numbers (mobile, home, work)
      - Date of birth
      - Profile photo
      - Preferred communication method
      - Preferred contact times
      - Language preference
      - Timezone

    Address Information:
      - Current address (full)
      - Previous addresses
      - Property ownership history
      - Rental history
      - Geographic preferences

    Professional Information:
      - Employer name
      - Job title
      - Industry
      - Annual income (encrypted)
      - Employment status
      - Years at current job

    Financial Profile:
      - Budget range
      - Pre-approval status
      - Pre-approval amount
      - Lender information
      - Down payment available
      - Credit score range
      - Debt-to-income ratio
      - Cash buyer status

    Family Information:
      - Marital status
      - Number of children
      - Ages of children
      - Pets (type, quantity)
      - School district importance
      - Special needs considerations

  Buyer Profile:
    Property Preferences:
      - Property types interested
      - Minimum bedrooms
      - Minimum bathrooms
      - Square footage range
      - Lot size preference
      - Garage/parking requirements
      - Must-have features
      - Nice-to-have features
      - Deal-breaker features

    Location Preferences:
      - Preferred cities/neighborhoods
      - School districts
      - Commute requirements
      - Lifestyle preferences
      - Proximity to amenities
      - Safety/crime concerns

    Timeline & Motivation:
      - Target move-in date
      - Current housing situation
      - Reason for moving
      - Urgency level
      - Flexibility on timeline
      - Backup plans

  Seller Profile:
    Current Property:
      - Property address
      - Property type
      - Current market value
      - Mortgage balance
      - Desired sale price
      - Property condition
      - Recent improvements
      - Known issues

    Motivation & Timeline:
      - Reason for selling
      - Target sale date
      - Move plans
      - Contingencies
      - Flexibility on price
      - Willingness to negotiate

  Engagement Tracking:
    Activity Metrics:
      - Total property views
      - Properties favorited
      - Showings attended
      - Inquiries submitted
      - Emails opened/clicked
      - Website visits
      - Social media interactions
      - Content downloads

    Communication History:
      - All emails (sent/received)
      - All text messages
      - Phone call logs
      - In-person meetings
      - Video calls
      - Social media messages
      - Notes and comments

    Marketing Engagement:
      - Campaigns received
      - Email response rate
      - SMS response rate
      - Best time for contact
      - Content preferences
      - Unsubscribe history

  Custom Fields:
    Field Types:
      - Text (short, long)
      - Number (integer, decimal)
      - Date/datetime
      - Dropdown (single select)
      - Multi-select
      - Checkbox (boolean)
      - URL
      - File upload

    Use Cases:
      - Industry-specific data
      - Agency-specific tracking
      - Compliance requirements
      - Regional information
      - Special programs
      - Partner integrations

  Relationship Mapping:
    Connections:
      - Spouse/partner
      - Family members
      - Business partners
      - Co-buyers
      - Referral sources
      - Professional network
      - Property co-owners

    Household Management:
      - Group contacts by household
      - Shared preferences
      - Joint communication
      - Combined documents
      - Household net worth
      - Shared calendar events

  Tags & Segmentation:
    Tag Categories:
      - Lead source tags
      - Interest tags
      - Behavior tags
      - Status tags
      - Campaign tags
      - Custom tags

    Smart Segments:
      - Rule-based segments
      - Behavioral segments
      - Demographic segments
      - Engagement level segments
      - Lifecycle stage segments
      - Dynamic segments (auto-update)

  Data Management:
    Import/Export:
      - CSV import
      - Excel import
      - VCard import
      - API data sync
      - Bulk updates
      - CSV/Excel export

    Data Quality:
      - Duplicate detection
      - Merge suggestions
      - Email validation
      - Phone validation
      - Address verification
      - Data enrichment

    Privacy & Compliance:
      - GDPR consent tracking
      - Data export requests
      - Right to be forgotten
      - Communication preferences
      - Opt-out management
      - Data retention policies
```

#### Pipeline Management
```yaml
Sales Pipeline:
  Pipeline Stages:
    Lead Stages:
      1. New Lead
         - Just captured
         - Not yet contacted
         - Auto-assignment pending

      2. Contacted
         - Initial contact made
         - Qualification in progress
         - Information gathering

      3. Qualified
         - Meets criteria
         - Budget confirmed
         - Timeline established
         - Ready for active work

    Active Buyer Stages:
      4. Property Search
         - Viewing properties
         - Refining criteria
         - Market education

      5. Showings Scheduled
         - Tours booked
         - Property comparisons
         - Decision-making phase

      6. Offer Preparation
         - Ready to make offer
         - Financing confirmed
         - Terms being discussed

      7. Offer Submitted
         - Offer presented
         - Awaiting response
         - Negotiations

      8. Under Contract
         - Offer accepted
         - Contingencies active
         - Closing timeline

    Closing Stages:
      9. Pre-Closing
         - Inspections complete
         - Financing finalized
         - Title cleared
         - Final walkthrough

      10. Closed/Won
          - Transaction complete
          - Commission earned
          - Client now homeowner

    Lost/Inactive:
      - Lost to Competitor
      - Not Ready/Timing
      - Unqualified
      - Unresponsive
      - No Longer Interested

  Pipeline Visualization:
    Kanban Board:
      - Drag-and-drop cards
      - Deal cards with key info
      - Color-coded by status
      - Priority indicators
      - Overdue warnings
      - Filtering and search

    List View:
      - Sortable columns
      - Bulk actions
      - Quick filters
      - Export to CSV
      - Customizable columns

    Forecast View:
      - Expected close dates
      - Probability-weighted value
      - Pipeline velocity
      - Conversion rates per stage
      - Bottleneck identification

  Deal Management:
    Deal Card Information:
      - Contact name and photo
      - Property address/details
      - Deal value/commission
      - Current stage
      - Days in current stage
      - Total days in pipeline
      - Win probability
      - Next action required
      - Assigned agent
      - Last activity date

    Deal Actions:
      - Move to different stage
      - Update deal value
      - Add/remove properties
      - Schedule activities
      - Add notes
      - Upload documents
      - Share with team
      - Set reminders
      - Mark as won/lost

    Automation:
      - Stage change triggers
      - Task creation on stage move
      - Email notifications
      - Reminders for stalled deals
      - Escalation rules
      - Auto-archive old deals

  Pipeline Analytics:
    Key Metrics:
      - Total pipeline value
      - Weighted pipeline (probability-adjusted)
      - Average deal size
      - Average sales cycle length
      - Win rate by stage
      - Loss rate by stage
      - Stage conversion rates
      - Pipeline velocity ($/day)
      - Stagnant deals (>30 days in stage)

    Forecasting:
      - Monthly forecast
      - Quarterly forecast
      - Confidence levels (best/worst/likely)
      - Historical accuracy
      - Trending analysis
      - Seasonality adjustments

    Performance Tracking:
      - Agent leaderboards
      - Team performance
      - Deal source ROI
      - Property type performance
      - Price range analysis
      - Geographic performance
```

### 4. Transaction Management

#### Deal Coordination
```yaml
Transaction Workspace:
  Overview Dashboard:
    Quick Stats:
      - Transaction status
      - Days until closing
      - Completion percentage
      - Pending tasks count
      - Overdue items
      - Document status

    Key Information:
      - Property details
      - Buyer information
      - Seller information
      - Financial summary
      - Important dates timeline
      - Contact directory

  Milestone Tracking:
    Pre-Contract Milestones:
      ☐ Offer prepared and reviewed
      ☐ Pre-approval letter obtained
      ☐ Earnest money deposit ready
      ☐ Offer submitted to seller
      ☐ Offer acceptance received

    Under Contract Milestones:
      ☐ Contract executed by all parties
      ☐ Earnest money deposited
      ☐ Title company engaged
      ☐ Escrow opened
      ☐ HOA documents requested

    Due Diligence Milestones:
      ☐ Home inspection scheduled
      ☐ Home inspection completed
      ☐ Inspection report reviewed
      ☐ Repair negotiations (if needed)
      ☐ Appraisal ordered
      ☐ Appraisal completed
      ☐ Title search completed
      ☐ Survey completed (if required)

    Financing Milestones:
      ☐ Loan application submitted
      ☐ Initial disclosure received
      ☐ Underwriting started
      ☐ Appraisal review by lender
      ☐ Clear to close received

    Pre-Closing Milestones:
      ☐ Final walkthrough scheduled
      ☐ Final walkthrough completed
      ☐ Closing disclosure reviewed
      ☐ Wire instructions verified
      ☐ Utilities transfer arranged
      ☐ Moving company scheduled
      ☐ Insurance binder obtained
      ☐ Keys & access codes confirmed

    Closing Milestones:
      ☐ Closing appointment confirmed
      ☐ All parties present/represented
      ☐ Documents signed
      ☐ Funds transferred
      ☐ Recording completed
      ☐ Keys transferred
      ☐ Possession confirmed

    Post-Closing:
      ☐ Commission processed
      ☐ Thank you gifts sent
      ☐ Review request sent
      ☐ Referral request sent
      ☐ Move-in checklist shared
      ☐ Added to client anniversary campaign

  Task Management:
    Task Types:
      Agent Tasks:
        - Schedule inspection
        - Review documents
        - Follow up with lender
        - Coordinate showings
        - Prepare disclosure
        - Attend closing

      Client Tasks:
        - Upload documents
        - Complete application
        - Review and sign contracts
        - Schedule walkthrough
        - Obtain insurance
        - Transfer utilities

      Third-Party Tasks:
        - Title company deliverables
        - Lender requirements
        - Inspector report
        - Appraiser schedule
        - Attorney review

    Task Features:
      - Priority levels
      - Due dates with reminders
      - Assignee(s)
      - Dependencies
      - Checklist items
      - File attachments
      - Comments/notes
      - Status tracking
      - Completion verification

  Timeline View:
    Visual Timeline:
      - All milestones plotted
      - Current date indicator
      - Completed items (green)
      - Upcoming items (blue)
      - Overdue items (red)
      - Critical path highlighted

    Date Management:
      - Contract date
      - Inspection contingency date
      - Appraisal contingency date
      - Financing contingency date
      - Title contingency date
      - Closing date
      - Possession date
      - All deadlines tracked

  Communication Hub:
    Participants:
      - Buyer(s)
      - Seller(s)
      - Buyer's agent
      - Listing agent
      - Transaction coordinator
      - Title company
      - Escrow officer
      - Lender
      - Inspector
      - Appraiser
      - Attorney

    Communication Tools:
      - Group messaging
      - Private messages
      - Email integration
      - SMS notifications
      - Document sharing
      - Activity feed
      - @mentions
      - Read receipts

  Document Repository:
    Document Categories:
      Purchase Documents:
        - Purchase agreement
        - Addendums
        - Counter-offers
        - Amendment forms
        - Earnest money receipt

      Disclosure Documents:
        - Seller disclosures
        - Lead paint disclosure
        - HOA documents
        - Property condition reports
        - Environmental reports

      Inspection & Appraisal:
        - Home inspection report
        - Pest inspection
        - Appraisal report
        - Survey
        - Property measurements

      Financing Documents:
        - Pre-approval letter
        - Loan application
        - Loan estimate
        - Closing disclosure
        - Final approval

      Title & Closing:
        - Title report
        - Title insurance policy
        - Closing statement (HUD-1)
        - Deed
        - Bill of sale

    Document Features:
      - Version control
      - E-signature integration
      - Access permissions
      - Expiration tracking
      - Automatic organization
      - Search functionality
      - Bulk download
      - Client portal access

  Financial Summary:
    Purchase Price Details:
      - List price
      - Offer price
      - Negotiated price
      - Earnest money
      - Down payment amount
      - Loan amount
      - Closing costs estimate
      - Total cash needed

    Seller Proceeds:
      - Sale price
      - Existing mortgage payoff
      - Closing costs
      - Commissions
      - Repairs/credits
      - Net proceeds

    Commission Breakdown:
      - Total commission
      - Listing side
      - Selling side
      - Agency split
      - Agent split
      - Transaction fee
      - Net to agent

Compliance Management:
  Regulatory Requirements:
    Federal Compliance:
      - RESPA requirements
      - TILA disclosures
      - Fair Housing Act
      - Equal Credit Opportunity Act
      - Anti-Money Laundering (AML)
      - USA PATRIOT Act

    State Requirements:
      - State-specific disclosures
      - License verification
      - State forms
      - Recording requirements
      - Transfer taxes

    Local Requirements:
      - City/county forms
      - Zoning compliance
      - Local transfer taxes
      - Municipal inspections

  Compliance Tracking:
    - Required documents checklist
    - Signature tracking
    - Disclosure delivery confirmation
    - Deadline adherence
    - Audit trail
    - Compliance reports
```

---

## Domain Models & Database Schema

### Core Domain Models

#### 1. Property Model
```ruby
class Property < ApplicationRecord
  # Identification
  id: uuid, primary_key: true
  mls_number: string, unique: true, indexed: true
  slug: string, unique: true, indexed: true

  # Basic Information
  title: string, limit: 200
  description: text
  property_type: enum [residential_single_family, residential_multi_family,
                       condo, townhouse, land, commercial, mixed_use]
  listing_type: enum [sale, rent, lease, sold, rented, off_market]
  status: enum [active, pending, under_contract, sold, expired,
                withdrawn, coming_soon, draft]

  # Location
  address_line_1: string
  address_line_2: string
  city: string, indexed: true
  state_province: string, indexed: true
  postal_code: string, indexed: true
  country: string, default: 'USA'
  latitude: decimal, precision: 10, scale: 6
  longitude: decimal, precision: 10, scale: 6
  county: string
  neighborhood: string
  subdivision: string
  school_district: string
  parcel_number: string
  legal_description: text

  # Physical Characteristics
  bedrooms: integer, default: 0
  bathrooms: decimal, precision: 3, scale: 1
  half_bathrooms: integer, default: 0
  square_feet: integer
  lot_size: decimal, precision: 10, scale: 2
  lot_size_unit: enum [sqft, acres, hectares]
  year_built: integer
  year_renovated: integer
  stories: integer
  rooms_total: integer
  garage_spaces: integer
  carport_spaces: integer
  parking_spaces: integer
  parking_type: enum [attached_garage, detached_garage, carport,
                     street, driveway, none]

  # Construction & Features
  construction_type: string # Frame, Brick, Stone, etc.
  roof_type: string
  foundation_type: string
  exterior_material: string
  flooring_types: text[], array: true
  heating_type: string
  cooling_type: string
  appliances_included: text[], array: true
  interior_features: jsonb
  exterior_features: jsonb
  community_features: jsonb

  # Amenities (boolean flags)
  pool: boolean, default: false
  pool_type: string # In-ground, Above-ground, etc.
  spa_hot_tub: boolean, default: false
  fireplace: boolean, default: false
  fireplace_count: integer
  basement: boolean, default: false
  basement_finished: boolean, default: false
  attic: boolean, default: false
  balcony_patio: boolean, default: false
  deck: boolean, default: false
  fenced_yard: boolean, default: false
  sprinkler_system: boolean, default: false
  security_system: boolean, default: false
  solar_panels: boolean, default: false
  electric_vehicle_charging: boolean, default: false
  smart_home_features: boolean, default: false
  wheelchair_accessible: boolean, default: false
  elevator: boolean, default: false

  # Utilities
  water_source: string
  sewer: string
  utilities_included: text[], array: true
  utility_average_cost: decimal

  # Financial Information
  list_price: decimal, precision: 12, scale: 2
  original_list_price: decimal, precision: 12, scale: 2
  previous_list_price: decimal, precision: 12, scale: 2
  price_per_sqft: decimal, precision: 10, scale: 2
  sold_price: decimal, precision: 12, scale: 2
  sold_price_per_sqft: decimal, precision: 10, scale: 2

  # HOA Information
  hoa_fee: decimal, precision: 8, scale: 2
  hoa_frequency: enum [monthly, quarterly, annually, one_time, none]
  hoa_name: string
  hoa_phone: string
  hoa_amenities: text[], array: true

  # Tax Information
  annual_tax_amount: decimal, precision: 10, scale: 2
  tax_year: integer
  tax_id: string
  tax_assessment: decimal, precision: 12, scale: 2

  # Listing Information
  listed_date: date
  available_date: date
  days_on_market: integer
  cumulative_days_on_market: integer
  sold_date: date
  closed_date: date
  pending_date: date
  off_market_date: date
  expiration_date: date

  # Showing Information
  showing_instructions: text
  lockbox_type: string
  lockbox_location: string
  showing_requirements: text
  occupancy_status: enum [owner_occupied, tenant_occupied, vacant]
  possession_type: enum [close_of_escrow, negotiable, specific_date]
  possession_date: date

  # Disclosure Information
  disclosures: jsonb
  property_condition: text
  known_issues: text
  recent_improvements: text
  improvement_costs: jsonb

  # Marketing Information
  featured: boolean, default: false, indexed: true
  featured_until: datetime
  featured_level: integer, default: 0
  virtual_tour_url: string
  video_tour_url: string
  matterport_url: string
  youtube_video_id: string
  floor_plan_url: string
  brochure_url: string

  # SEO & Content
  seo_title: string
  seo_description: text
  seo_keywords: text[], array: true
  meta_tags: jsonb
  og_image_url: string

  # Syndication
  syndicate_to_zillow: boolean, default: true
  syndicate_to_realtor: boolean, default: true
  syndicate_to_trulia: boolean, default: true
  syndication_status: jsonb
  last_syndicated_at: datetime

  # Performance Metrics
  views_count: integer, default: 0
  inquiries_count: integer, default: 0
  favorites_count: integer, default: 0
  shares_count: integer, default: 0
  showings_count: integer, default: 0
  offers_count: integer, default: 0
  listing_views_by_source: jsonb
  average_time_on_page: integer # seconds

  # Relationships (Foreign Keys)
  agency_id: uuid, null: false, indexed: true
  listing_agent_id: uuid, null: false, indexed: true
  co_listing_agent_id: uuid, indexed: true
  created_by_id: uuid, indexed: true
  updated_by_id: uuid, indexed: true

  # Soft Delete
  deleted_at: datetime, indexed: true

  # Timestamps
  created_at: datetime, null: false
  updated_at: datetime, null: false

  # Associations
  belongs_to :agency
  belongs_to :listing_agent, class_name: 'Agent'
  belongs_to :co_listing_agent, class_name: 'Agent', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :property_photos, dependent: :destroy
  has_many :property_videos, dependent: :destroy
  has_many :property_documents, dependent: :destroy
  has_many :property_features, dependent: :destroy
  has_many :open_houses, dependent: :destroy
  has_many :property_inquiries, dependent: :destroy
  has_many :property_showings, dependent: :destroy
  has_many :property_favorites, dependent: :destroy
  has_many :property_views, dependent: :destroy
  has_many :property_shares, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :marketing_campaigns, through: :campaign_properties
  has_many :landing_pages, through: :landing_page_properties
  has_one :transaction, dependent: :destroy

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :available, -> { where(status: [:active, :coming_soon]) }
  scope :featured, -> { where(featured: true).where('featured_until > ?', Time.current) }
  scope :by_city, ->(city) { where(city: city) }
  scope :by_property_type, ->(type) { where(property_type: type) }
  scope :price_range, ->(min, max) { where(list_price: min..max) }
  scope :min_bedrooms, ->(count) { where('bedrooms >= ?', count) }
  scope :min_bathrooms, ->(count) { where('bathrooms >= ?', count) }
  scope :with_pool, -> { where(pool: true) }
  scope :recent_listings, -> { where('listed_date > ?', 30.days.ago) }
  scope :price_reduced, -> { where('list_price < original_list_price') }

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :property_type, presence: true
  validates :listing_type, presence: true
  validates :status, presence: true
  validates :address_line_1, presence: true
  validates :city, presence: true
  validates :state_province, presence: true
  validates :postal_code, presence: true
  validates :list_price, presence: true, numericality: { greater_than: 0 }
  validates :bedrooms, numericality: { greater_than_or_equal_to: 0 }
  validates :bathrooms, numericality: { greater_than: 0 }
  validates :mls_number, uniqueness: true, allow_nil: true
  validates :slug, uniqueness: true

  # Callbacks
  before_validation :generate_slug
  before_save :calculate_price_per_sqft
  before_save :calculate_days_on_market
  after_create :syndicate_to_portals
  after_update :update_syndication, if: :saved_change_to_list_price?

  # Instance Methods
  def full_address
    [address_line_1, address_line_2, city, state_province, postal_code].compact.join(', ')
  end

  def price_formatted
    "$#{list_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  def available_for_showing?
    status.in?(['active', 'under_contract']) && !deleted_at
  end

  def is_price_reduced?
    list_price < original_list_price
  end

  def price_reduction_percentage
    return 0 if original_list_price.zero?
    ((original_list_price - list_price) / original_list_price * 100).round(2)
  end

  def generate_description_from_ai
    # AI-powered description generation logic
  end

  private

  def generate_slug
    self.slug ||= "#{city}-#{property_type}-#{SecureRandom.hex(4)}".parameterize
  end

  def calculate_price_per_sqft
    self.price_per_sqft = list_price / square_feet if square_feet && square_feet > 0
  end

  def calculate_days_on_market
    self.days_on_market = (Date.today - listed_date).to_i if listed_date
  end
end
```

#### 2. Lead Model
```ruby
class Lead < ApplicationRecord
  # Identification
  id: uuid, primary_key: true
  lead_number: string, unique: true, indexed: true

  # Personal Information
  first_name: string, indexed: true
  last_name: string, indexed: true
  email: string, indexed: true
  secondary_email: string
  phone: string, indexed: true
  secondary_phone: string
  mobile_phone: string
  work_phone: string
  preferred_contact_method: enum [email, phone, sms, whatsapp, video_call]
  best_time_to_contact: string
  timezone: string

  # Address
  address_line_1: string
  address_line_2: string
  city: string
  state_province: string
  postal_code: string
  country: string, default: 'USA'

  # Demographics
  date_of_birth: date
  age: integer
  gender: enum [male, female, non_binary, prefer_not_to_say]
  language: string, default: 'en'
  marital_status: enum [single, married, divorced, widowed, domestic_partnership]
  number_of_children: integer
  children_ages: integer[], array: true
  pets: jsonb # {dogs: 2, cats: 1}

  # Professional Information
  employer: string
  job_title: string
  industry: string
  annual_income: decimal, precision: 12, scale: 2 # Encrypted
  employment_status: enum [employed, self_employed, retired, unemployed, student]
  years_at_current_job: integer

  # Lead Classification
  lead_source: string, indexed: true
  lead_source_detail: string
  lead_medium: string # organic, paid, referral, direct
  lead_campaign: string
  referrer_url: text
  landing_page_url: text
  utm_parameters: jsonb

  lead_type: enum [buyer, seller, renter, investor, both]
  lead_status: enum [new, contacted, attempted_contact, qualified,
                     nurturing, active, converted, lost, unqualified,
                     on_hold, do_not_contact], default: 'new', indexed: true

  lead_quality: enum [hot, warm, cold, unqualified], indexed: true
  lead_score: integer, default: 0, indexed: true
  score_breakdown: jsonb

  # Buyer Profile
  buyer_type: enum [first_time, repeat, investor, relocating,
                    downsizing, upsizing, vacation_home]

  min_price: decimal, precision: 12, scale: 2
  max_price: decimal, precision: 12, scale: 2
  ideal_price: decimal, precision: 12, scale: 2

  preferred_bedrooms: integer
  preferred_bathrooms: decimal, precision: 3, scale: 1
  preferred_square_feet_min: integer
  preferred_square_feet_max: integer

  preferred_property_types: text[], array: true
  preferred_locations: jsonb # {cities: [], neighborhoods: [], zip_codes: []}
  preferred_features: text[], array: true
  must_have_features: text[], array: true
  deal_breaker_features: text[], array: true

  move_in_timeline: enum [immediate, within_30_days, 1_3_months,
                          3_6_months, 6_12_months, over_1_year, flexible]
  urgency_level: enum [very_urgent, somewhat_urgent, exploring, no_rush]
  reason_for_moving: text

  # Financing Information
  financing_status: enum [pre_approved, getting_approved, need_to_apply,
                          cash_buyer, unknown]
  pre_approval_amount: decimal, precision: 12, scale: 2
  lender_name: string
  lender_contact: string
  down_payment_amount: decimal, precision: 12, scale: 2
  down_payment_percentage: integer
  credit_score_range: string
  first_time_buyer: boolean, default: false
  needs_to_sell_first: boolean, default: false

  # Seller Profile
  current_property_address: text
  current_property_value: decimal, precision: 12, scale: 2
  desired_sale_price: decimal, precision: 12, scale: 2
  mortgage_balance: decimal, precision: 12, scale: 2
  property_condition: text
  reason_for_selling: text
  target_sale_date: date
  move_plans: text

  # Engagement Metrics
  properties_viewed: integer, default: 0
  properties_favorited: integer, default: 0
  inquiries_submitted: integer, default: 0
  showings_attended: integer, default: 0
  emails_sent: integer, default: 0
  emails_opened: integer, default: 0
  emails_clicked: integer, default: 0
  sms_sent: integer, default: 0
  sms_responded: integer, default: 0
  calls_made: integer, default: 0
  calls_answered: integer, default: 0
  website_visits: integer, default: 0
  total_page_views: integer, default: 0
  average_session_duration: integer # seconds
  last_activity_at: datetime, indexed: true
  last_contacted_at: datetime
  last_responded_at: datetime
  last_email_sent_at: datetime
  last_sms_sent_at: datetime
  last_call_at: datetime
  first_response_time: integer # minutes

  # Assignment & Routing
  assigned_agent_id: uuid, indexed: true
  assigned_team_id: uuid, indexed: true
  agency_id: uuid, null: false, indexed: true
  assignment_date: datetime
  assignment_method: enum [manual, auto_round_robin, auto_geographic,
                           auto_performance, auto_specialization]
  previous_agent_id: uuid

  # Marketing Consent & Preferences
  email_opt_in: boolean, default: true
  sms_opt_in: boolean, default: true
  phone_opt_in: boolean, default: true
  mail_opt_in: boolean, default: true
  third_party_sharing: boolean, default: false

  gdpr_consent: boolean
  gdpr_consent_date: datetime
  gdpr_consent_ip: string
  ccpa_opt_out: boolean, default: false

  unsubscribed_from_all: boolean, default: false
  unsubscribed_at: datetime
  unsubscribe_reason: text

  do_not_email: boolean, default: false
  do_not_call: boolean, default: false
  do_not_sms: boolean, default: false

  # Additional Information
  notes: text
  internal_notes: text # Not visible to lead
  tags: text[], array: true, indexed: using: :gin
  custom_fields: jsonb
  metadata: jsonb

  # Conversion Tracking
  converted_to_client: boolean, default: false, indexed: true
  converted_at: datetime
  conversion_value: decimal, precision: 12, scale: 2
  client_id: uuid, indexed: true

  # Loss Tracking
  lost_reason: enum [purchased_elsewhere, timing_not_right, unresponsive,
                     poor_fit, budget_mismatch, other]
  lost_reason_detail: text
  lost_at: datetime
  competitor_name: string

  # IP & Device Tracking
  ip_address: string
  user_agent: text
  device_type: enum [desktop, mobile, tablet]
  browser: string
  operating_system: string
  geolocation: jsonb

  # Soft Delete
  deleted_at: datetime, indexed: true

  # Timestamps
  created_at: datetime, null: false, indexed: true
  updated_at: datetime, null: false

  # Associations
  belongs_to :agency
  belongs_to :assigned_agent, class_name: 'Agent', optional: true
  belongs_to :assigned_team, class_name: 'Team', optional: true
  belongs_to :previous_agent, class_name: 'Agent', optional: true
  belongs_to :client, optional: true

  has_many :lead_activities, dependent: :destroy
  has_many :lead_notes, dependent: :destroy
  has_many :property_inquiries, dependent: :destroy
  has_many :property_favorites, dependent: :destroy
  has_many :favorite_properties, through: :property_favorites, source: :property
  has_many :property_showings, dependent: :destroy
  has_many :property_views, dependent: :destroy
  has_many :campaign_recipients, dependent: :destroy
  has_many :campaigns, through: :campaign_recipients
  has_many :email_activities, dependent: :destroy
  has_many :sms_activities, dependent: :destroy
  has_many :call_activities, dependent: :destroy
  has_many :meeting_activities, dependent: :destroy
  has_many :tasks, as: :taskable, dependent: :destroy

  # Scopes
  scope :active, -> { where(lead_status: [:new, :contacted, :qualified, :nurturing, :active]) }
  scope :hot_leads, -> { where(lead_quality: :hot) }
  scope :new_leads, -> { where(lead_status: :new) }
  scope :qualified_leads, -> { where(lead_status: :qualified) }
  scope :converted, -> { where(converted_to_client: true) }
  scope :assigned_to, ->(agent_id) { where(assigned_agent_id: agent_id) }
  scope :by_source, ->(source) { where(lead_source: source) }
  scope :recent, ->(days = 7) { where('created_at > ?', days.days.ago) }
  scope :stale, ->(days = 30) { where('last_activity_at < ?', days.days.ago) }
  scope :buyers, -> { where(lead_type: [:buyer, :both]) }
  scope :sellers, -> { where(lead_type: [:seller, :both]) }

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, presence: true
  validates :lead_type, presence: true
  validates :lead_status, presence: true
  validates :agency_id, presence: true
  validates :lead_number, uniqueness: true

  # Callbacks
  before_create :generate_lead_number
  before_create :calculate_initial_score
  after_create :assign_to_agent
  after_create :trigger_welcome_automation
  after_update :recalculate_score, if: :engagement_changed?
  after_update :notify_agent_of_hot_lead, if: :became_hot_lead?

  # Instance Methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def contact_info
    {
      email: email,
      phone: phone,
      preferred_method: preferred_contact_method
    }
  end

  def engagement_level
    return 'High' if lead_score >= 70
    return 'Medium' if lead_score >= 40
    'Low'
  end

  def days_since_last_contact
    return nil unless last_contacted_at
    (Date.today - last_contacted_at.to_date).to_i
  end

  def qualified?
    lead_status.in?(['qualified', 'active', 'nurturing'])
  end

  def hot?
    lead_quality == 'hot'
  end

  def calculate_score
    # Complex lead scoring algorithm
    score = 0

    # Demographic factors (20%)
    score += 10 if budget_in_range?
    score += 10 if in_service_area?
    score += 15 if financing_status == 'pre_approved'
    score += 20 if financing_status == 'cash_buyer'

    # Behavioral factors (40%)
    score += [properties_viewed * 2, 10].min
    score += [emails_opened * 1, 10].min
    score += [emails_clicked * 3, 15].min
    score += [website_visits * 1, 5].min

    # Engagement factors (25%)
    score += 10 if inquiries_submitted > 0
    score += 15 if showings_attended > 0
    score += 10 if calls_answered > 0

    # Intent signals (15%)
    score += 5 if properties_favorited > 0
    score += 5 if used_mortgage_calculator?
    score += 5 if downloaded_resources?

    # Time decay
    days_inactive = (Date.today - (last_activity_at&.to_date || created_at.to_date)).to_i
    decay_factor = [0.5, 1 - (days_inactive * 0.01)].max

    final_score = (score * decay_factor).round
    [100, [0, final_score].max].min
  end

  def update_quality_from_score
    self.lead_quality = case lead_score
    when 90..100 then 'hot'
    when 70..89 then 'warm'
    when 50..69 then 'cold'
    else 'unqualified'
    end
  end

  private

  def generate_lead_number
    self.lead_number = "L#{Date.today.strftime('%Y%m')}#{SecureRandom.hex(4).upcase}"
  end

  def calculate_initial_score
    self.lead_score = calculate_score
    update_quality_from_score
  end

  def engagement_changed?
    saved_change_to_properties_viewed? ||
    saved_change_to_emails_opened? ||
    saved_change_to_emails_clicked? ||
    saved_change_to_showings_attended?
  end

  def became_hot_lead?
    saved_change_to_lead_quality? && lead_quality == 'hot'
  end
end
```

---

## Business Logic & Workflows

### Lead Scoring Algorithm Implementation

```ruby
# app/services/leads/scoring_service.rb
class Leads::ScoringService < ApplicationService
  def initialize(lead)
    @lead = lead
    @score_breakdown = {}
  end

  def call
    calculate_demographic_score
    calculate_behavioral_score
    calculate_engagement_score
    calculate_intent_score
    apply_time_decay

    final_score = total_score_with_decay
    @lead.update(
      lead_score: final_score,
      score_breakdown: @score_breakdown,
      lead_quality: determine_quality(final_score)
    )

    success(lead: @lead, score: final_score)
  end

  private

  def calculate_demographic_score
    demographic_score = 0

    # Budget alignment (10 points)
    if budget_in_range?
      demographic_score += 10
      @score_breakdown[:budget_aligned] = 10
    end

    # Location match (10 points)
    if location_in_service_area?
      demographic_score += 10
      @score_breakdown[:location_match] = 10
    end

    # Financing status (15-20 points)
    case @lead.financing_status
    when 'pre_approved'
      demographic_score += 15
      @score_breakdown[:financing_status] = 15
    when 'cash_buyer'
      demographic_score += 20
      @score_breakdown[:financing_status] = 20
    end

    # First-time buyer bonus (5 points)
    if @lead.first_time_buyer
      demographic_score += 5
      @score_breakdown[:first_time_buyer] = 5
    end

    @score_breakdown[:demographic_total] = demographic_score
    demographic_score
  end

  def calculate_behavioral_score
    behavioral_score = 0

    # Property views (max 10 points: 2 points per view)
    property_view_score = [@lead.properties_viewed * 2, 10].min
    behavioral_score += property_view_score
    @score_breakdown[:property_views] = property_view_score

    # Email opens (max 10 points: 1 point per open)
    email_open_score = [@lead.emails_opened * 1, 10].min
    behavioral_score += email_open_score
    @score_breakdown[:email_opens] = email_open_score

    # Email clicks (max 15 points: 3 points per click)
    email_click_score = [@lead.emails_clicked * 3, 15].min
    behavioral_score += email_click_score
    @score_breakdown[:email_clicks] = email_click_score

    # Website visits (max 5 points: 1 point per visit)
    visit_score = [@lead.website_visits * 1, 5].min
    behavioral_score += visit_score
    @score_breakdown[:website_visits] = visit_score

    @score_breakdown[:behavioral_total] = behavioral_score
    behavioral_score
  end

  def calculate_engagement_score
    engagement_score = 0

    # Inquiry submitted (10 points)
    if @lead.inquiries_submitted > 0
      engagement_score += 10
      @score_breakdown[:inquiries] = 10
    end

    # Showings attended (15 points)
    if @lead.showings_attended > 0
      engagement_score += 15
      @score_breakdown[:showings] = 15
    end

    # Phone calls (10 points)
    if @lead.calls_answered > 0
      engagement_score += 10
      @score_breakdown[:calls] = 10
    end

    # Multiple touchpoints bonus (5 points)
    if touchpoint_count >= 3
      engagement_score += 5
      @score_breakdown[:multi_touchpoint] = 5
    end

    @score_breakdown[:engagement_total] = engagement_score
    engagement_score
  end

  def calculate_intent_score
    intent_score = 0

    # Properties favorited (5 points)
    if @lead.properties_favorited > 0
      intent_score += 5
      @score_breakdown[:favorites] = 5
    end

    # Mortgage calculator usage (5 points)
    if @lead.used_mortgage_calculator?
      intent_score += 5
      @score_breakdown[:mortgage_calc] = 5
    end

    # Downloaded resources (5 points)
    if @lead.downloaded_resources?
      intent_score += 5
      @score_breakdown[:downloads] = 5
    end

    # Urgency level (0-10 points)
    urgency_score = case @lead.urgency_level
    when 'very_urgent' then 10
    when 'somewhat_urgent' then 7
    when 'exploring' then 3
    else 0
    end
    intent_score += urgency_score
    @score_breakdown[:urgency] = urgency_score

    @score_breakdown[:intent_total] = intent_score
    intent_score
  end

  def apply_time_decay
    days_inactive = (Date.today - (@lead.last_activity_at&.to_date || @lead.created_at.to_date)).to_i

    # Exponential decay: lose 1% per day inactive, minimum 50% retention
    @decay_factor = [0.5, 1 - (days_inactive * 0.01)].max
    @score_breakdown[:decay_factor] = (@decay_factor * 100).round
    @score_breakdown[:days_inactive] = days_inactive
  end

  def total_score_with_decay
    base_score = @score_breakdown.values_at(
      :demographic_total,
      :behavioral_total,
      :engagement_total,
      :intent_total
    ).compact.sum

    @score_breakdown[:base_score] = base_score
    final_score = (base_score * @decay_factor).round
    [100, [0, final_score].max].min
  end

  def determine_quality(score)
    case score
    when 90..100 then 'hot'
    when 70..89 then 'warm'
    when 50..69 then 'cold'
    else 'unqualified'
    end
  end

  def budget_in_range?
    return false unless @lead.max_price
    agency_price_ranges.include?(@lead.max_price)
  end

  def location_in_service_area?
    return false unless @lead.preferred_locations.present?
    agency_service_areas.intersect?(@lead.preferred_locations)
  end

  def touchpoint_count
    count = 0
    count += 1 if @lead.emails_opened > 0
    count += 1 if @lead.calls_answered > 0
    count += 1 if @lead.inquiries_submitted > 0
    count += 1 if @lead.showings_attended > 0
    count += 1 if @lead.website_visits > 0
    count
  end
end
```

### Marketing Automation Workflows

```ruby
# app/workflows/lead_nurture_workflow.rb
class LeadNurtureWorkflow
  attr_reader :lead

  def initialize(lead)
    @lead = lead
  end

  def execute
    case lead.lead_quality
    when 'hot'
      execute_hot_lead_workflow
    when 'warm'
      execute_warm_lead_workflow
    when 'cold'
      execute_cold_lead_workflow
    else
      execute_unqualified_workflow
    end
  end

  private

  def execute_hot_lead_workflow
    # Immediate response sequence
    send_immediate_response_email
    notify_assigned_agent_urgent
    schedule_follow_up_call(within: 5.minutes)

    # Day 1-3: Aggressive follow-up
    schedule_email(template: 'hot_lead_day_1', delay: 4.hours)
    schedule_sms(template: 'hot_lead_check_in', delay: 1.day)
    schedule_email(template: 'property_matches', delay: 2.days)

    # Day 4-7: Value delivery
    schedule_email(template: 'market_insights', delay: 4.days)
    schedule_phone_call(delay: 5.days)

    # Week 2: Conversion push
    schedule_email(template: 'exclusive_listings', delay: 10.days)
    schedule_showing_invitation(delay: 12.days)
  end

  def execute_warm_lead_workflow
    # Standard follow-up sequence
    send_welcome_email
    notify_assigned_agent_standard
    schedule_follow_up_call(within: 1.hour)

    # Week 1: Build relationship
    schedule_email(template: 'warm_lead_intro', delay: 1.day)
    schedule_email(template: 'buyer_guide', delay: 3.days)
    schedule_email(template: 'neighborhood_guide', delay: 5.days)

    # Week 2-3: Engagement
    schedule_email(template: 'new_listings_alert', delay: 8.days)
    schedule_email(template: 'market_update', delay: 14.days)
    schedule_phone_call(delay: 15.days)

    # Week 4+: Long-term nurture
    schedule_email(template: 'monthly_digest', delay: 28.days, recurring: true)
  end

  def execute_cold_lead_workflow
    # Educational drip campaign
    send_welcome_email
    assign_to_team_pool

    # Month 1: Education
    schedule_email(template: 'home_buying_101', delay: 2.days)
    schedule_email(template: 'financing_options', delay: 7.days)
    schedule_email(template: 'neighborhood_comparison', delay: 14.days)
    schedule_email(template: 'market_trends', delay: 21.days)

    # Month 2+: Stay top of mind
    schedule_email(template: 'monthly_market_report', delay: 60.days, recurring: true)
    schedule_email(template: 'success_stories', delay: 90.days)

    # Re-engagement attempts
    schedule_reengagement_campaign(delay: 90.days)
  end

  def execute_unqualified_workflow
    # Minimal touch campaign
    send_thank_you_email

    # Quarterly check-ins
    schedule_email(template: 'quarterly_update', delay: 90.days, recurring: true)

    # Re-qualification attempt
    schedule_qualification_survey(delay: 180.days)
  end

  # Helper methods for scheduling
  def send_immediate_response_email
    EmailService.deliver_now(
      lead: @lead,
      template: 'immediate_response',
      subject: "Thank you for your inquiry!"
    )
  end

  def notify_assigned_agent_urgent
    NotificationService.send_urgent_alert(
      agent: @lead.assigned_agent,
      message: "Hot lead assigned: #{@lead.full_name}",
      priority: 'high',
      channels: [:email, :sms, :push]
    )
  end

  def schedule_email(template:, delay:, recurring: false)
    MarketingAutomation::ScheduleEmailJob.perform_in(
      delay,
      lead_id: @lead.id,
      template: template,
      recurring: recurring
    )
  end

  def schedule_sms(template:, delay:)
    MarketingAutomation::ScheduleSMSJob.perform_in(
      delay,
      lead_id: @lead.id,
      template: template
    )
  end

  def schedule_phone_call(delay:)
    Task.create(
      taskable: @lead,
      assigned_to: @lead.assigned_agent,
      task_type: 'phone_call',
      due_date: Time.current + delay,
      priority: 'high',
      title: "Follow-up call with #{@lead.full_name}"
    )
  end

  def schedule_showing_invitation(delay:)
    MarketingAutomation::ScheduleEmailJob.perform_in(
      delay,
      lead_id: @lead.id,
      template: 'showing_invitation',
      dynamic_content: {
        properties: @lead.recommended_properties.limit(5)
      }
    )
  end
end
```

---

## Marketing Automation Engine

### Campaign Management System

```yaml
Campaign Types:
  Email Campaigns:
    - Newsletter broadcasts
    - Promotional campaigns
    - Drip sequences
    - Behavioral triggers
    - Event-based campaigns
    - Re-engagement campaigns

  SMS Campaigns:
    - Text alerts
    - Appointment reminders
    - Time-sensitive offers
    - Status updates
    - Quick polls

  Multi-Channel Campaigns:
    - Coordinated messaging
    - Sequential touchpoints
    - Channel-specific content
    - Unified tracking

Campaign Builder:
  Visual Workflow Editor:
    - Drag-and-drop interface
    - Conditional logic branches
    - Wait/delay steps
    - A/B testing splits
    - Goal conversion tracking

  Triggers:
    - Lead capture
    - Property view
    - Email open/click
    - Website behavior
    - Form submission
    - Status change
    - Date-based (anniversaries)
    - Inactivity (30/60/90 days)

  Actions:
    - Send email
    - Send SMS
    - Assign to agent
    - Create task
    - Update lead score
    - Add/remove tags
    - Change status
    - Trigger webhook
    - Start another workflow

Campaign Analytics:
  Performance Metrics:
    - Delivery rate
    - Open rate
    - Click rate
    - Conversion rate
    - Unsubscribe rate
    - ROI calculation
    - Revenue attribution

  Engagement Tracking:
    - Individual recipient activity
    - Heat maps (email clicks)
    - Device analytics
    - Time-of-day performance
    - Geographic engagement
```

---

## Analytics & Reporting

### Performance Dashboard

```yaml
Key Performance Indicators:
  Lead Metrics:
    - Total leads generated
    - Lead sources breakdown
    - Conversion rate by source
    - Cost per lead
    - Lead quality distribution
    - Response time averages
    - Follow-up completion rate

  Agent Performance:
    - Leads assigned
    - Leads contacted
    - Showings scheduled
    - Offers submitted
    - Deals closed
    - Revenue generated
    - Average response time
    - Client satisfaction score

  Property Metrics:
    - Total listings
    - Active vs. sold
    - Average days on market
    - Views per listing
    - Inquiries per listing
    - Showing-to-offer ratio
    - List-to-sold price ratio

  Marketing ROI:
    - Campaign performance
    - Channel attribution
    - Marketing spend
    - Revenue per campaign
    - Customer acquisition cost
    - Return on ad spend

Reporting Features:
  Standard Reports:
    - Daily activity summary
    - Weekly team performance
    - Monthly revenue report
    - Quarterly trends analysis
    - Annual business review

  Custom Reports:
    - Report builder interface
    - Custom metrics selection
    - Flexible date ranges
    - Multiple visualization types
    - Scheduled delivery
    - Export formats (PDF, Excel, CSV)

  Real-Time Dashboards:
    - Live data updates
    - Customizable widgets
    - Drag-and-drop layout
    - Role-based views
    - Mobile-optimized
```

---

## API & Integration Layer

### RESTful API Endpoints

```yaml
Authentication:
  POST /api/v1/auth/login
  POST /api/v1/auth/register
  POST /api/v1/auth/refresh
  POST /api/v1/auth/logout

Properties:
  GET    /api/v1/properties
  POST   /api/v1/properties
  GET    /api/v1/properties/:id
  PATCH  /api/v1/properties/:id
  DELETE /api/v1/properties/:id

  GET    /api/v1/properties/:id/photos
  POST   /api/v1/properties/:id/photos
  DELETE /api/v1/properties/:id/photos/:photo_id

  GET    /api/v1/properties/:id/inquiries
  POST   /api/v1/properties/:id/inquiries

Leads:
  GET    /api/v1/leads
  POST   /api/v1/leads
  GET    /api/v1/leads/:id
  PATCH  /api/v1/leads/:id
  DELETE /api/v1/leads/:id

  POST   /api/v1/leads/:id/score
  POST   /api/v1/leads/:id/assign
  POST   /api/v1/leads/:id/convert

  GET    /api/v1/leads/:id/activities
  POST   /api/v1/leads/:id/activities
  GET    /api/v1/leads/:id/notes
  POST   /api/v1/leads/:id/notes

Campaigns:
  GET    /api/v1/campaigns
  POST   /api/v1/campaigns
  GET    /api/v1/campaigns/:id
  PATCH  /api/v1/campaigns/:id
  DELETE /api/v1/campaigns/:id

  POST   /api/v1/campaigns/:id/start
  POST   /api/v1/campaigns/:id/pause
  GET    /api/v1/campaigns/:id/analytics

Webhooks:
  POST   /api/v1/webhooks/zillow
  POST   /api/v1/webhooks/realtor
  POST   /api/v1/webhooks/stripe
  POST   /api/v1/webhooks/twilio

Third-Party Integrations:
  - Zillow API integration
  - Realtor.com API
  - Google My Business
  - Facebook/Instagram Marketing
  - Stripe payment processing
  - Twilio SMS/Voice
  - SendGrid email delivery
  - AWS S3 file storage
  - Zapier webhooks
  - MLS data feeds
```

---

## Technical Architecture

### Technology Stack

```yaml
Backend:
  Framework: Ruby on Rails 8.0+
  Language: Ruby 3.3+
  Database: PostgreSQL 15+
  Cache: Redis 7+
  Search: Elasticsearch 8+
  Queue: Sidekiq / Solid Queue
  File Storage: AWS S3 / Active Storage

Frontend:
  Framework: Hotwire (Turbo + Stimulus)
  CSS: TailwindCSS 3+
  JavaScript: ES6+
  Build Tool: Import Maps / esbuild
  UI Components: ViewComponent

Infrastructure:
  Hosting: AWS / Digital Ocean / Fly.io
  Deployment: Kamal / Docker
  CDN: CloudFront / Cloudflare
  Monitoring: New Relic / Datadog
  Logging: Papertrail / CloudWatch
  Error Tracking: Sentry / Rollbar

Security:
  Authentication: JWT tokens
  Authorization: Pundit policies
  Encryption: At rest and in transit
  HTTPS: TLS 1.3
  Rate Limiting: Rack::Attack
  CSRF Protection: Built-in Rails

Compliance:
  GDPR: Data privacy controls
  CCPA: California privacy rights
  Fair Housing: Anti-discrimination
  RESPA: Real estate settlement
  CAN-SPAM: Email marketing
```

### Deployment Architecture

```yaml
Production Environment:
  Load Balancer:
    - SSL termination
    - Health checks
    - Auto-scaling triggers
    - Geographic routing

  Application Servers:
    - Multiple instances (3+ minimum)
    - Auto-scaling based on load
    - Rolling deployment strategy
    - Zero-downtime updates

  Database Cluster:
    - Primary-replica replication
    - Automated backups (hourly)
    - Point-in-time recovery
    - Read replicas for reporting

  Cache Layer:
    - Redis cluster
    - Session storage
    - Fragment caching
    - Full-page caching

  Background Jobs:
    - Multiple worker pools
    - Priority queues
    - Job retry logic
    - Dead letter queue

  File Storage:
    - CDN distribution
    - Image optimization
    - Video transcoding
    - Backup retention

Monitoring & Alerting:
  - Application performance monitoring
  - Server health metrics
  - Database query analysis
  - Error rate tracking
  - Uptime monitoring
  - Security alerts
  - Business metrics
```

---

## Implementation Roadmap

### Phase 1: Foundation (Months 1-3)

**Core Platform Setup:**
- User authentication and authorization
- Agency and agent management
- Basic property listing CRUD
- Lead capture forms
- Contact management
- Email notification system
- Admin dashboard

**Deliverables:**
- Functioning property listing system
- Basic lead management
- User roles and permissions
- Email notifications
- Mobile-responsive interface

### Phase 2: Marketing Tools (Months 4-6)

**Marketing Automation:**
- Email campaign builder
- Drip campaign workflows
- SMS integration
- Social media posting
- Landing page builder
- Lead scoring system
- Property syndication to portals

**Deliverables:**
- Complete marketing automation suite
- Multi-channel campaign management
- Automated lead nurturing
- Property distribution network
- Performance analytics dashboard

### Phase 3: Advanced Features (Months 7-9)

**CRM & Transaction Management:**
- Sales pipeline management
- Transaction coordination
- Document management
- E-signature integration
- Calendar and scheduling
- Task management
- Client portal
- Reporting and analytics

**Deliverables:**
- Full-featured CRM
- Transaction management system
- Document repository
- Advanced analytics
- Client self-service portal

### Phase 4: AI & Optimization (Months 10-12)

**Intelligent Features:**
- AI-powered lead scoring
- Predictive analytics
- Chatbot integration
- Property description generation
- Image recognition and tagging
- Market trend analysis
- Recommendation engine

**Deliverables:**
- AI-enhanced lead qualification
- Intelligent property recommendations
- Automated content generation
- Predictive business insights
- Machine learning models

### Phase 5: Scale & Enterprise (Months 12+)

**Enterprise Features:**
- Multi-office management
- Franchise support
- White-label platform
- API marketplace
- Advanced integrations
- Enterprise reporting
- Custom workflows
- SLA guarantees

**Deliverables:**
- Enterprise-ready platform
- White-label solution
- Advanced API ecosystem
- Enterprise-grade security
- 99.9% uptime SLA

---

## Success Metrics

### Business Outcomes

**Lead Generation:**
- 300% increase in lead capture rate
- 40% improvement in lead quality scores
- 60% reduction in cost per lead
- 85% reduction in lead response time

**Conversion Optimization:**
- 45% increase in lead-to-showing conversion
- 35% increase in showing-to-offer conversion
- 25% increase in close rate
- 20% reduction in sales cycle length

**Agent Productivity:**
- 50% reduction in administrative time
- 3x increase in touchpoints per lead
- 40% more showings scheduled
- 30% increase in deals closed per agent

**Marketing ROI:**
- 200% return on marketing spend
- 70% reduction in marketing costs
- 90% improvement in campaign performance
- 100% visibility into attribution

---

## Conclusion

This comprehensive real estate marketing platform combines cutting-edge technology with deep industry knowledge to deliver a complete solution for property marketing, lead management, client relationship building, and transaction coordination. By automating repetitive tasks, providing intelligent insights, and enabling seamless collaboration, the platform empowers real estate professionals to focus on what they do best: building relationships and closing deals.

The platform's modular architecture allows for flexible deployment, whether as a complete end-to-end solution or as individual components integrated into existing systems. With robust APIs, extensive third-party integrations, and white-label capabilities, the platform scales from individual agents to large enterprise brokerages.

---

**Platform Vision Statement:**

"Transforming real estate marketing through intelligent automation, data-driven insights, and seamless technology—empowering agents to maximize property exposure, capture qualified leads, nurture client relationships, and close more deals faster than ever before."

---

*Document Version: 1.0*
*Last Updated: January 2025*
*Next Review: Quarterly*