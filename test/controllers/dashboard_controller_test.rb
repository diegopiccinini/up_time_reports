require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :unauthorized
  end

end
