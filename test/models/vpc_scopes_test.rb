require 'test_helper'

class VpcScopesTest < ActiveSupport::TestCase

  setup do

    vpc = vpcs(:one)

    @start_date = Date.today.at_beginning_of_month.prev_month.to_time
    @end_date = Date.today.to_time

    @total = vpc.outages_by_dates( from: @start_date, to: @end_date).count
    @up = vpc.up( from: @start_date, to: @end_date).count
    @down = vpc.down( from: @start_date, to: @end_date).count

  end

  test "outages scopes" do

    assert @up > 0
    assert @down > 0
    assert_equal @total , @up + @down

  end
end
