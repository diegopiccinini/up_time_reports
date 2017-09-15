require 'test_helper'

class ReportTest < ActiveSupport::TestCase

  setup do
    @date = 1.day.ago
    @period = 'day'
  end

  test "#server_time" do

    server_time =Report.server_time

    assert_kind_of Time, server_time
    assert (Time.new - server_time) < 1.0

  end

  test "Report generators" do

    Report.start @date
    assert Report.started(@date).count > 0
    assert_equal Report.started(@date).count, Vpc.count

    Report.save_performance @date
    assert Report.performance_saved(@date).count > 0
    assert Report.performance_saved(@date).count < Performance.count
    assert_equal Report.performance_saved_total(@date).count, Vpc.count

  end

end
