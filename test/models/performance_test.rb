require 'test_helper'

class PerformanceTest < ActiveSupport::TestCase
  setup do
    @from = Date.yesterday.to_time
    @to = Date.today.to_time
    @report=reports(:one)
    stub_performance(check_id: @report.vpc.id, from: @from.to_i, to: @to.to_i)
    @report.update_performances
    @report.update_outages

  end

  test "Scopes" do
    assert_equal 24, @report.performances.count
    total_time = 24 * 3600

    performance_total_time = @report.performances.all.sum { |x| x.uptime + x.downtime + x.unmonitored }

    assert_equal total_time, performance_total_time
    assert_equal @report.uptime,      @report.performances_uptime
    assert_equal @report.downtime,    @report.performances_downtime
    assert_equal @report.unmonitored, @report.performances_unmonitored
    assert @report.avgresponse>0

  end
end
