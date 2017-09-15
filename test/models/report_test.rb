require 'test_helper'

class ReportTest < ActiveSupport::TestCase


  test "#server_time" do

    server_time =Report.server_time

    assert_kind_of Time, server_time
    assert (Time.new - server_time) < 1.0

  end

  test "#start" do

    result=Report.start date: 1.day.ago, period: 'day'
    assert result[:reports] > 0
    assert_equal result[:reports] , Report.where( period: 'day', start_date: 1.day.ago, status: 'start' ).count
    assert_equal result[:reports] , Vpc.count

  end


end
