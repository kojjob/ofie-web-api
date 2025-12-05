require "test_helper"

class Properties::CreateServiceTest < ActiveSupport::TestCase
  setup do
    @landlord = create(:user, :landlord)
    @tenant = create(:user, :tenant)
    @valid_params = {
      title: "Beautiful Downtown Apartment",
      description: "Spacious 2BR apartment in downtown",
      address: "123 Main St",
      city: "San Francisco",
      price: 2500,
      bedrooms: 2,
      bathrooms: 1,
      square_feet: 1000,
      property_type: "apartment"
    }
  end

  test "creates property successfully with valid params" do
    result = Properties::CreateService.call(
      user: @landlord,
      params: @valid_params
    )

    assert result.success?, "Expected service to succeed but got errors: #{result.errors.inspect if result.respond_to?(:errors)}"
    assert_instance_of Property, result.property
    assert_equal @valid_params[:title], result.property.title
    assert_equal @landlord, result.property.user
  end

  test "fails when user is not a landlord" do
    assert_no_difference "Property.count" do
      result = Properties::CreateService.call(
        user: @tenant,
        params: @valid_params
      )

      assert result.failure?
      assert_includes result.errors, "User must be a landlord"
    end
  end

  test "fails with invalid params" do
    invalid_params = @valid_params.merge(price: -100)

    assert_no_difference "Property.count" do
      result = Properties::CreateService.call(
        user: @landlord,
        params: invalid_params
      )

      assert result.failure?
      assert_not_empty result.errors
    end
  end
end
