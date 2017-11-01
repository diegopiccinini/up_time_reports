require 'test_helper'

class VpcsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vpc = vpcs(:one)
  end

  test "should get index" do
    get vpcs_url
    assert_response :success
  end

  test "should get new" do
    get new_vpc_url
    assert_response :success
  end

  test "should create vpc" do
    assert_difference('Vpc.count') do
      post vpcs_url, params: { vpc: {  } }
    end

    assert_redirected_to vpc_url(Vpc.last)
  end

  test "should show vpc" do
    get vpc_url(@vpc)
    assert_response :success
  end

  test "should get edit" do
    get edit_vpc_url(@vpc)
    assert_response :success
  end

  test "should update vpc" do
    patch vpc_url(@vpc), params: { vpc: {  } }
    assert_redirected_to vpc_url(@vpc)
  end

  test "should destroy vpc" do
    assert_difference('Vpc.count', -1) do
      delete vpc_url(@vpc)
    end

    assert_redirected_to vpcs_url
  end
end
