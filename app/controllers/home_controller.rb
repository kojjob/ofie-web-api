class HomeController < ApplicationController
  skip_before_action :authenticate_request, only: [ :index ]

  def index
    # Featured properties for the landing page
    @featured_properties = Property.where(availability_status: "available")
                                  .includes(:photos_attachments)
                                  .limit(6)
                                  .order(created_at: :desc)

    # Statistics for the hero section
    @total_properties = Property.count
    @available_properties = Property.where(availability_status: "available").count
    @total_users = User.count
    @cities_count = Property.distinct.count(:city)
  end
end
