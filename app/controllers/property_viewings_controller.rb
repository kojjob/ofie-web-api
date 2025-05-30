class PropertyViewingsController < ApplicationController
  before_action :set_property
  before_action :set_property_viewing, only: [ :show, :update, :destroy ]
  before_action :authenticate_request, except: [ :available_slots ]

  def index
    @property_viewings = @property.property_viewings.includes(:user)
                                 .order(scheduled_at: :desc)
                                 .page(params[:page])
  end

  def show
  end

  def new
    @property_viewing = @property.property_viewings.build
  end

  def create
    @property_viewing = @property.property_viewings.build(property_viewing_params)
    @property_viewing.user = current_user

    # Combine date and time
    if params[:property_viewing][:scheduled_at].present? && params[:property_viewing][:time_slot].present?
      date = Date.parse(params[:property_viewing][:scheduled_at])
      time = Time.parse(params[:property_viewing][:time_slot])
      @property_viewing.scheduled_at = date.beginning_of_day + time.seconds_since_midnight.seconds
    end

    if @property_viewing.save
      # Send notifications
      PropertyViewingMailer.viewing_requested(@property_viewing).deliver_later
      PropertyViewingMailer.viewing_confirmation(@property_viewing).deliver_later

      redirect_to @property, notice: "Property viewing was successfully scheduled. You will receive a confirmation email shortly."
    else
      redirect_to @property, alert: "Error scheduling viewing: " + @property_viewing.errors.full_messages.join(", ")
    end
  end

  def update
    if @property_viewing.update(property_viewing_params)
      redirect_to [ @property, @property_viewing ], notice: "Viewing was successfully updated."
    else
      render :show, alert: "Error updating viewing."
    end
  end

  def destroy
    @property_viewing.update(status: "cancelled")
    redirect_to @property, notice: "Viewing was cancelled."
  end

  # API endpoint for checking available time slots
  def available_slots
    date = Date.parse(params[:date]) rescue Date.current

    # Get existing bookings for the date
    existing_bookings = @property.property_viewings
                                .where(scheduled_at: date.beginning_of_day..date.end_of_day)
                                .where.not(status: [ "cancelled", "no_show" ])
                                .pluck(:scheduled_at)

    # Generate available slots (9 AM to 6 PM, 30-minute intervals)
    available_slots = []
    (9..17).each do |hour|
      [ 0, 30 ].each do |minute|
        slot_time = date.beginning_of_day + hour.hours + minute.minutes
        next if slot_time < Time.current + 2.hours # Minimum 2 hours notice

        unless existing_bookings.include?(slot_time)
          available_slots << {
            time: slot_time.strftime("%H:%M"),
            display: slot_time.strftime("%l:%M %p").strip,
            available: true
          }
        end
      end
    end

    render json: { slots: available_slots }
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_property_viewing
    @property_viewing = @property.property_viewings.find(params[:id])
  end

  def property_viewing_params
    params.require(:property_viewing).permit(
      :scheduled_at, :contact_phone, :contact_email, :notes,
      :viewing_type, :email_notifications, :sms_notifications
    )
  end
end
