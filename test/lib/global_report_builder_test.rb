require 'test_helper'

class GlobalReportBuilderTest < ActiveSupport::TestCase
=begin
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
    report_generator period: 'day', resolution: resolution
  end

  def weekly_setup resolution: 'day'
    to=GlobalSetting.date_in_default_timezone Date.parse('Monday')
    @date = to.prev_week
    to=to.to_time.to_i
    from=@date.to_time.to_i
    stubs_setup from: from, to: to, resolution: resolution
    report_generator period: 'week', resolution: resolution
  end

  def monthly_setup resolution: 'day'
    from=1504224000
    to=1506729600
    @date=Time.at(from).in_time_zone('UTC').to_date

    if resolution=='week'
      from=1503878400
      @date=Time.at(from).in_time_zone('UTC').to_date
      to=1507420800
    end

    @date=GlobalSetting.date_in_default_timezone @date

    stubs_setup from: from, to: to , resolution: resolution

    report_generator period: 'month', resolution: resolution
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

    @global_report=GlobalReport.start date: @date, period: period, resolution: resolution
    @global_report.save_performances
    @global_report.save_outages
    @global_report.vpc_reports_build

  end

  def builder_asserts rows_per_report
    builder=GlobalReportBuilder.new @global_report
    builder.build
    total_rows=builder.data[:rows].count
    assert total_rows>0
    assert_equal total_rows, (@global_report.reports.json_ready.count * rows_per_report)
  end

  test "Report day generator" do

    daily_setup
    builder_asserts 24

  end

  test "Report week generator" do

    weekly_setup
    builder_asserts 7

  end

  test "Report month generator day resolution" do

    monthly_setup resolution: 'day'
    builder_asserts @date.at_end_of_month.day

  end

  test "Report month generator week resolution" do

    monthly_setup resolution: 'week'
    builder_asserts 4

  end
=end
end
