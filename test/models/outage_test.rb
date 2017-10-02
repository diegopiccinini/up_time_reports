require 'test_helper'

class OutageTest < ActiveSupport::TestCase

  setup do
    @from = Date.yesterday.to_time
    @to = Date.today.to_time
    @report=reports(:one)
    stub_outage(check_id: @report.vpc.id, from: @from.to_i, to: @to.to_i)
    @report.update_outages
  end

  test "Scopes" do

    up_o = @report.outages.up(@from,@to)
    up = up_o.count
    uptime = up_o.all.sum { |x| x.interval }

    down_o = @report.outages.down(@from,@to)
    down = down_o.count
    downtime = down_o.all.sum { |x| x.interval }

    unknown_o = @report.outages.unknown(@from,@to)
    unknown = unknown_o.count
    unmonitored = unknown_o.all.sum { |x| x.interval }

    total = @report.outages.by_period(@from,@to).count

    total_time = @to.to_i - @from.to_i

    outages_total_time = @report.outages.all.sum { |x| x.interval }


    assert_equal total_time, 24 * 3600
    assert_equal total_time, outages_total_time

    assert total > 1
    assert_equal total, @report.outages.count
    assert_equal (up + down + unknown), total
    assert_equal @report.outage_uptime, uptime
    assert_equal @report.outage_downtime, downtime
    assert_equal @report.outage_unknown, unmonitored


    total=Outage.count
    adjusted= Outage.adjusted.count
    assert adjusted<total
    Outage.adjusted.each do |o|
      o.interval<GlobalSetting.adjust_interval
    end

  end
end
