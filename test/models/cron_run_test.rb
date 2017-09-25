require 'test_helper'

class CronRunTest < ActiveSupport::TestCase

  setup do

    stub_checks
    History.start 'Vpc Check'
    Vpc.update_from_checks
    History.finish

    # the fixture vpcs cannot get a performance
    @fixture_vpcs=Vpc.where("name like ?",'%Fixture%').all.map { |vpc| vpc.id }
  end

  def daily_setup resolution: 'hour'
    @date = Date.yesterday
    to=Date.today.to_time.to_i
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

  test "#run!" do
    daily_setup
    cron=crons(:one)
    cron.run!
    cron.reload
    assert_equal cron.status, 'running'
  end

end
