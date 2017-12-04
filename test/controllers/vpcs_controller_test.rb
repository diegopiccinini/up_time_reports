require 'test_helper'

class VpcsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @vpc = vpcs(:one)
    sign_in users(:one)
  end

  test "should get index" do
    get vpcs_url
    assert_response :success
  end


  test "should show vpc" do
    get vpc_url(@vpc)
    assert_response :success
  end

end
