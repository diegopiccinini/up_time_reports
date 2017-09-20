require 'test_helper'

class StubTest < ActiveSupport::TestCase

  test "outage data" do
    from = Date.yesterday.to_time.to_i
    to = Date.today.to_time.to_i
    outage=outage_build_data 1, from, to
    assert_kind_of Hash, outage
    assert_equal outage[:summary][:states].first[:timefrom], from
    assert_equal outage[:summary][:states].last[:timeto], to
    assert_equal GlobalSetting.get(to_key('outage_data',1,from,to)),outage
    assert_equal outage_data(1,from,to),outage
  end
end
