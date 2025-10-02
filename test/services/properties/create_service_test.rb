require "test_helper"

class Properties::CreateServiceTest < ActiveSupport::TestCase
  setup do
    @landlord = users(:landlord)
    @tenant = users(:tenant)
    @valid_params = {
      title: "Beautiful Downtown Apartment",
      description: "Spacious 2BR apartment in downtown",
      address: "123 Main St",
      city: "San Francisco",
      state: "CA",
      zip_code: "94102",
      price: 2500,
      bedrooms: 2,
      bathrooms: 1,
      square_feet: 1000,
      property_type: "apartment",
      pet_friendly: true,
      parking_available: true
    }
  end

  test "creates property successfully with valid params" do
    assert_difference "Property.count", 1 do
      result = Properties::CreateService.call(
        user: @landlord,
        params: @valid_params
      )

      assert result.success?
      assert_instance_of Property, result.property
      assert_equal @valid_params[:title], result.property.title
      assert_equal @landlord, result.property.user
    end
  end

  test "fails when user is not a landlord" do
    result = Properties::CreateService.call(
      user: @tenant,
      params: @valid_params
    )

    assert result.failure?
    assert_includes result.errors, "User must be a landlord"
    assert_no_difference "Property.count"
  end

  test "fails with invalid params" do
    invalid_params = @valid_params.merge(price: -100)

    result = Properties::CreateService.call(
      user: @landlord,
      params: invalid_params
    )

    assert result.failure?
    assert_not_empty result.errors
    assert_no_difference "Property.count"
  end

  test "handles image attachments" do
    params_with_images = @valid_params.merge(
      images: [
        fixture_file_upload("test/fixtures/files/property1.jpg", "image/jpeg"),
        fixture_file_upload("test/fixtures/files/property2.jpg", "image/jpeg")
      ]
    )

    result = Properties::CreateService.call(
      user: @landlord,
      params: params_with_images
    )

    assert result.success?
    assert_equal 2, result.property.images.count
  end

  test "schedules indexing job after creation" do
    assert_enqueued_with(job: PropertyIndexJob) do
      Properties::CreateService.call(
        user: @landlord,
        params: @valid_params
      )
    end
  end

  test "sends notifications after creation" do
    assert_enqueued_with(job: NotificationJob) do
      Properties::CreateService.call(
        user: @landlord,
        params: @valid_params
      )
    end
  end
end
