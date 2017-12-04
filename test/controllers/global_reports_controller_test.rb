require 'test_helper'

class GlobalReportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @global_report = global_reports(:real_24)
    sign_in users(:one)
  end

  test "should get index" do
    get global_reports_url
    assert_response :success
  end


  test "should show global_report" do
    get global_report_url(@global_report)
    assert_response :success
  end

end
