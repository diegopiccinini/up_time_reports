require 'test_helper'

class ReportGeneratorJobTest < ActiveJob::TestCase

  setup do
    @now=Time.now
    @date = GlobalSetting.date_in_default_timezone Date.yesterday
    @date= @date.at_beginning_of_month

    stub_checks
    to = (@date + 1.day).to_time

    History.start "Vpc Jobs"
    Vpc.update_from_checks
    History.finish

    Vpc.checks.each do |check|
      stub_performance check_id: check.id, from: @date.to_time.to_i, to: to.to_i, resolution: 'hour'
      stub_outage check_id: check.id, from: @date.to_time.to_i, to: to.to_i
    end

    # the fixture vpcs cannot get a performance
    @fixture_vpcs=Vpc.where("name like ?",'%Fixture%').all.map { |vpc| vpc.id }
    @fixture_vpcs.each do |vpc_id|
      stub_performance_error check_id: vpc_id, from: @date.to_time.to_i, to: to.to_i, resolution: 'hour'
    end
    History.reset
    @history=ReportGeneratorJob.perform_now(date: @date,cron: crons(:one))
  end

  teardown do
    GlobalReport.where(start_date: @date).each do |gr|
      gr.reports.destroy_all
      gr.destroy
    end
  end

  test "reports outage was saved" do

    global_report= GlobalReport.find_by start_date: @date
    assert_equal global_report.reports.count, Vpc.count

    # fixture errors saved
    assert_equal global_report.reports.performances_saved_total.count, @fixture_vpcs.count
    # outage saved
    outage_saved= Vpc.count - @fixture_vpcs.count
    assert_equal global_report.reports.outages_saved.count, outage_saved
  end

  test "history tracker" do
    assert_equal @history.history.status, 'started'
    assert_equal @history.status, 'finished'
    assert_equal @history.cron.status, 'ok'
    assert @history.cron.last_execution>@now
  end

end
