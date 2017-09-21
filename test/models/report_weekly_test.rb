require 'test_helper'

class ReportWeeklyTest < ActiveSupport::TestCase

  setup do
    History.start 'WeeklyReportJob'
    stub_checks

    to = Date.parse('Monday')
    @date = to.prev_week
    to=to.to_time.to_i
    from=@date.to_time.to_i

    Vpc.update_from_checks
    Vpc.checks.each do |check|
      stub_performance check_id: check.id, from: from, to: to, resolution: 'day'
      stub_outage check_id: check.id, from: from, to: from
    end

    # the fixture vpcs cannot get a performance
    @fixture_vpcs=Vpc.where("name like ?",'%Fixture%').all.map { |vpc| vpc.id }
    @fixture_vpcs.each do |vpc_id|
      stub_performance_error check_id: vpc_id, from: from, to: to, resolution: 'day'
    end
  end

  teardown do
    History.finish 'WeeklyReportJob'
  end

  test "Report week generator" do

    period='week'
    # step 1 report start
    Report.start @date, period: period, resolution: 'day'
    assert Report.started(@date,period).count > 0
    assert_equal Report.started(@date,period).count, Vpc.count

    # step 2 save_performances
    Report.save_performances @date, period
    updated =  Report.performances_saved_total(@date,period).count
    ok =  Report.performances_saved(@date,period).count
    with_error = updated - ok
    assert ok > 0
    assert ok < Performance.count
    assert with_error, @fixture_vpcs.count
    assert_equal updated, Vpc.count

    # step 3 save_outages
    Report.save_outages @date, period
    assert_equal Report.outages_saved(@date,period).count, ok

    # step 4 check results
    Report.outages_saved(@date,period).each do |r|
      assert r.uptime>0
      assert_equal r.uptime, r.performances_uptime
      assert_equal r.downtime, r.performances_downtime
      assert_equal r.unmonitored, r.performances_unmonitored
    end

  end

end
