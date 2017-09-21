require 'test_helper'

class ReportTest < ActiveSupport::TestCase

  test "#server_time" do
    stub_servertime
    server_time =Report.server_time

    assert_kind_of Time, server_time
    assert (Time.now - server_time) < 3

  end

end
