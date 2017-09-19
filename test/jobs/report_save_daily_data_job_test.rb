require 'test_helper'

class ReportSaveDailyDataJobTest < ActiveJob::TestCase

  setup do
    @date = Date.yesterday.at_beginning_of_month
    Report.where(start_date: @date).delete_all

    stub_checks
    to = (@date + 1).to_time - 1
    Vpc.update_from_checks
    Vpc.checks.each do |check|
      stub_performance check_id: check.id, from: @date.to_time.to_i, to: to.to_i
      stub_outage check_id: check.id, from: @date.to_time.to_i, to: to.to_i
    end

    # the fixture vpcs cannot get a performance
    @fixture_vpcs=Vpc.where("name like ?",'%Fixture%').all.map { |vpc| vpc.id }
    @fixture_vpcs.each do |vpc_id|
      stub_performance_error check_id: vpc_id, from: @date.to_time.to_i, to: to.to_i
    end
  end

  teardown do
    Report.where(start_date: @date).each do |r|
      r.performances.delete_all
      r.delete
    end
  end

  test "reports outage was saved" do
    ReportSaveDailyDataJob.perform_now(@date)
    assert_equal Report.where(start_date: @date).count,5

    # fixture errors saved
    assert_equal Report.performance_saved_total(@date).count,2
    # outage saved
    assert_equal Report.outage_saved(@date).count,3

  end

end
