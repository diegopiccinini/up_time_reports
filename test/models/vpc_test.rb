require 'test_helper'

class VpcTest < ActiveSupport::TestCase

  setup do
    stub_checks
  end

  test "#checks" do
    checks = Vpc.checks
    check = checks.first
    assert checks.count > 0
    assert_kind_of Pingdom::Check, check
    assert_respond_to check, :hostname
    assert_respond_to check, :id
    assert_respond_to check, :lasterrortime
    assert_respond_to check, :lastresponsetime
    assert_respond_to check, :lasttesttime
    assert_respond_to check, :name
    assert_respond_to check, :resolution
    assert_respond_to check, :status
    assert_respond_to check, :type
    assert_respond_to check, :tags
  end

  test "#update_from_checks" do

    ufc = Vpc.update_from_checks
    assert ufc[:total]>0
    assert_equal ( ufc[:created] + ufc[:updated] ), ufc[:total]
    assert_equal Vpc.checks.count, ufc[:total]

  end

end
