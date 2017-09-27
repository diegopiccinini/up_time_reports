require 'test_helper'

class ReportGeneratorTest < ActiveSupport::TestCase

  setup do
    History.start 'ReportJob'
    stub_checks
    Vpc.update_from_checks
    # the fixture vpcs cannot get a performance
    @fixture_vpcs=Vpc.where("name like ?",'%Fixture%').all.map { |vpc| vpc.id }
  end

  teardown do
    History.finish 'ReportJob'
  end

  def daily_setup resolution: 'hour'
    @date = Date.yesterday
    to=Date.today.to_time.to_i
    from=@date.to_time.to_i
    stubs_setup from: from, to: to, resolution: resolution
  end

  def weekly_setup resolution: 'day'
    to = Date.parse('Monday')
    @date = to.prev_week
    to=to.to_time.to_i
    from=@date.to_time.to_i
    stubs_setup from: from, to: to, resolution: resolution
  end

  def monthly_setup resolution: 'day'
    to = Date.today.at_beginning_of_month
    @date = to.prev_month

    if resolution=='week'
      @date-=1 until @date.wday==1
      to-=1 until to.wday==1
    end

    to=to.to_time.to_i
    from=@date.to_time.to_i

    stubs_setup from: from, to: to, resolution: resolution
  end

  def stubs_setup from: , to: , resolution:
    Vpc.checks.each do |check|
      stub_performance check_id: check.id, from: from, to: to, resolution: resolution
      stub_outage check_id: check.id, from: from, to: from
    end

    @fixture_vpcs.each do |vpc_id|
      stub_performance_error check_id: vpc_id, from: from, to: to, resolution: resolution
    end
  end

  def report_generator period:, resolution:

    # step 1 report start
    Report.start @date, period: period, resolution: resolution
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

  test "Report day generator" do

    daily_setup
    report_generator period: 'day', resolution: 'hour'

  end

  test "Report week generator" do

    weekly_setup
    report_generator period: 'week', resolution: 'day'

  end

  test "Report month generator day resolution" do

    monthly_setup resolution: 'day'
    report_generator period: 'month', resolution: 'day'

  end

  test "Report month generator week resolution" do

    monthly_setup resolution: 'week'
    report_generator period: 'month', resolution: 'week'

  end

end
