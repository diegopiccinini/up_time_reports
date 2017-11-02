require 'test_helper'

class GlobalReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @global_report = global_reports(:one)
  end

  test "should get index" do
    get global_reports_url
    assert_response :success
  end

  test "should get new" do
    get new_global_report_url
    assert_response :success
  end

  test "should create global_report" do
    assert_difference('GlobalReport.count') do
      post global_reports_url, params: { global_report: {  } }
    end

    assert_redirected_to global_report_url(GlobalReport.last)
  end

  test "should show global_report" do
    get global_report_url(@global_report)
    assert_response :success
  end

  test "should get edit" do
    get edit_global_report_url(@global_report)
    assert_response :success
  end

  test "should update global_report" do
    patch global_report_url(@global_report), params: { global_report: {  } }
    assert_redirected_to global_report_url(@global_report)
  end

  test "should destroy global_report" do
    assert_difference('GlobalReport.count', -1) do
      delete global_report_url(@global_report)
    end

    assert_redirected_to global_reports_url
  end
end
