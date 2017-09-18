require 'test_helper'

class ReportTest < ActiveSupport::TestCase

  setup do
    stub_checks
    stub_servertime
    @date = Date.yesterday
    @period = 'day'
    to = Date.today.to_time - 1
    Vpc.update_from_checks
    Vpc.checks.each do |check|
      stub_performance check_id: check.id, from: @date.to_time.to_i, to: to.to_i
      stub_outage check_id: check.id, from: @date.to_time.to_i, to: to.to_i
    end

    # the fixture vpcs cannot get a performance
    @fixture_vpcs=Vpc.where("name like ?",'%Fixture%').all
    @fixture_vpcs.each do |vpc|
      stub_performance_error check_id: vpc.id, from: @date.to_time.to_i, to: to.to_i
    end
  end

  test "#server_time" do

    server_time =Report.server_time

    assert_kind_of Time, server_time
    assert (Time.now - server_time) < 1.0

  end

  test "Report generators" do

    # report start
    Report.start @date
    assert Report.started(@date).count > 0
    assert_equal Report.started(@date).count, Vpc.count

    # step 2 save_performance
    Report.save_performance @date
    updated =  Report.performance_saved_total(@date).count
    ok =  Report.performance_saved(@date).count
    with_error = updated - ok
    assert updated > 0
    assert ok < Performance.count
    assert with_error, @fixture_vpcs.count
    assert_equal updated, Vpc.count

    # step 3 save_outage
    Report.save_outage @date
    assert_equal Report.outage_saved(@date).count, ok
    assert ok < Outage.count

  end

end
