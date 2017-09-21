require 'test_helper'

class ReportDailyTest < ActiveSupport::TestCase

  setup do
    History.start 'ReportJob'
    stub_checks
    @date = Date.yesterday
    to = Date.today.to_time
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
    History.finish 'ReportJob'
  end

  test "Report day generator" do

    # step 1 report start
    Report.start @date
    assert Report.started(@date).count > 0
    assert_equal Report.started(@date).count, Vpc.count

    # step 2 save_performances
    Report.save_performances @date
    updated =  Report.performances_saved_total(@date).count
    ok =  Report.performances_saved(@date).count
    with_error = updated - ok
    assert ok > 0
    assert ok < Performance.count
    assert with_error, @fixture_vpcs.count
    assert_equal updated, Vpc.count

    # step 3 save_outages
    Report.save_outages @date
    assert_equal Report.outages_saved(@date).count, ok

    # step 4 check results
    Report.outages_saved(@date).each do |r|
      assert r.uptime>0
      assert_equal r.uptime, r.performances_uptime
      assert_equal r.downtime, r.performances_downtime
      assert_equal r.unmonitored, r.performances_unmonitored
    end

  end

end
