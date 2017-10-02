require 'test_helper'

class PerformanceTest < ActiveSupport::TestCase

  setup do
    @from = Date.yesterday.to_time
    @to = Date.today.to_time
    @report=reports(:one)
    stub_performance(check_id: @report.vpc.id, from: @from.to_i, to: @to.to_i)
    @report.update_performances
    @report.update_outages
    @one = performances(:one)
  end

  test "Scopes" do
    assert_equal 24, @report.performances.count
    total_time = 24 * 3600

    performance_total_time = @report.performances.all.sum { |x| x.uptime + x.downtime + x.unmonitored }

    assert_equal total_time, performance_total_time
    assert_equal @report.outage_uptime,      @report.performance_uptime
    assert_equal @report.outage_downtime,    @report.performance_downtime
    assert_equal @report.outage_unknown, @report.performance_unmonitored
    assert @report.performance_avgresponse>0

  end

  test "endtime" do
    assert_equal @one.starttime.hour, 0
    assert_equal @one.endtime.hour, 1
  end

  test "incidents" do
    r=reports(:one)
    assert_equal r.performances.count, 24
    assert_equal performances(:one).incidents, 1
    assert_equal performances(:two).incidents, 0
    assert_equal performances(:seven).incidents, 1
  end

  test "adjust incidents" do
    assert_equal performances(:one).adjusted_incidents, 0
    assert_equal performances(:two).adjusted_incidents, 0
    assert_equal performances(:seven).adjusted_incidents, 1
  end
end
