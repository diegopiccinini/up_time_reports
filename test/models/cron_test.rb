require 'test_helper'

class CronTest < ActiveSupport::TestCase

  test "#in_range? with only hour" do
    cron = crons(:one)
    assert cron.in_range?(Time.parse('08:00:00'),Time.parse('09:00:00'))
    assert cron.in_range?(Time.parse('07:00:00'),Time.parse('08:00:00'))
    assert_not cron.in_range?(Time.parse('08:00:01'),Time.parse('09:00:00'))
    assert_not cron.in_range?(Time.parse('07:00:00'),Time.parse('07:59:59'))
    assert_not cron.in_range?(Time.parse('09:00:00'),Time.parse('10:00:00'))
  end

  test "#in_range? with hour and day_of_week" do
    cron = crons(:at_8_on_monday)
    monday=Date.parse 'Monday'
    tuesday=Date.parse 'Tuesday'

    assert cron.in_range?(monday.to_time + 8.hours,monday.to_time + 9.hours)
    assert_not cron.in_range?(monday.to_time + 9.hours,monday.to_time + 10.hours)
    assert_not cron.in_range?(tuesday.to_time + 8.hours,tuesday.to_time + 9.hours)
  end

  test "#in_day_of_week?" do
    cron = crons(:at_8_on_monday)
    monday=Date.parse 'Monday'
    tuesday=Date.parse 'Tuesday'

    assert cron.in_day_of_week?(monday)
    assert_not cron.in_day_of_week?(tuesday)
  end
end
