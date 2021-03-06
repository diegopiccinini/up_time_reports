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
    @date=GlobalSetting.date_in_default_timezone Date.yesterday
    to=@date.next_day.to_time.to_i
    from=@date.to_time.to_i
    stubs_setup from: from, to: to, resolution: resolution
  end

  def weekly_setup resolution: 'day'
    to=GlobalSetting.date_in_default_timezone Date.parse('Monday')
    @date = to.prev_week
    to=to.to_time.to_i - 1.day.to_i
    from=@date.to_time.to_i
    stubs_setup from: from, to: to, resolution: resolution
  end

  def monthly_setup resolution: 'day'
    to=Date.today.prev_month.at_end_of_month
    to=GlobalSetting.date_in_default_timezone to

    @date = to.at_beginning_of_month

    if resolution=='week'
      @date-=1.day until @date.wday==1
      to-=1.day until to.wday==0
    end

    @date=GlobalSetting.date_in_default_timezone @date

    stubs_setup from: @date.to_i, to: to.to_i , resolution: resolution

  end

  def stubs_setup from: , to: , resolution:
    Vpc.checks.each do |check|
    stub_performance check_id: check.id, from: from, to: to, resolution: resolution
    stub_outage check_id: check.id, from: from, to: from, resolution: resolution
  end

  @fixture_vpcs.each do |vpc_id|
    stub_performance_error check_id: vpc_id, from: from, to: to, resolution: resolution
  end
  end

  def report_generator period:, resolution:

    # step 1 report start
    global_report=GlobalReport.start date: @date, period: period, resolution: resolution
    vpc_included =Vpc.created_before(global_report.to).count
    assert global_report.reports.started.count > 0
    assert_equal global_report.reports.started.count, vpc_included

    # step 2 save_performances
    global_report.save_performances
    updated =  global_report.reports.performances_saved_total.count
    ok =  global_report.reports.performances_saved.count
    with_error = updated - ok
    assert ok > 0
    assert ok < Performance.count
    assert with_error, @fixture_vpcs.count
    assert_equal updated, vpc_included

    # step 3 save_outages
    global_report.save_outages
    assert_equal global_report.reports.outages_saved.count, ok

    # step 4 check results
    global_report.reports.outages_saved.each do |r|
      assert r.outage_uptime>0
      if resolution!='week'
        assert_equal r.outage_uptime, r.performance_uptime
        assert_equal r.outage_downtime, r.performance_downtime
        assert_equal r.outage_unknown, r.performance_unmonitored
      end
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
