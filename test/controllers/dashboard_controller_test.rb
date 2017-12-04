require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "should get index" do
    sign_in users(:one)
    get root_url
    assert_response :success
    sign_out users(:one)
  end

  test "should get unauthorized" do
    get root_url
    assert_response :redirect
  end

end
