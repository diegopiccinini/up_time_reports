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


  test "#in_day_of_week?" do
    cron = crons(:at_8_on_monday)
    monday=Date.parse 'Monday'
    tuesday=Date.parse 'Tuesday'

    assert cron.in_day_of_week?(monday)
    assert_not cron.in_day_of_week?(tuesday)
  end

  test "#in_range? with hour and day_of_week" do
    cron = crons(:at_8_on_monday)
    monday=Date.parse 'Monday'
    tuesday=Date.parse 'Tuesday'

    assert cron.in_range?(monday.to_time + 8.hours,monday.to_time + 9.hours)
    assert_not cron.in_range?(monday.to_time + 9.hours,monday.to_time + 10.hours)
    assert_not cron.in_range?(tuesday.to_time + 8.hours,tuesday.to_time + 9.hours)
  end

  test "#in_day_of_month?" do
    cron = crons(:at_8_on_1st_of_month)
    first_of_month=Date.today.at_beginning_of_month
    second_of_month=first_of_month + 1

    assert cron.in_day_of_month?(first_of_month)
    assert_not cron.in_day_of_month?(second_of_month)

  end

  test "#in_range? with hour and day_of_month" do
    cron = crons(:at_8_on_1st_of_month)
    first_of_month=Date.today.at_beginning_of_month
    second_of_month=first_of_month + 1

    assert cron.in_range?(first_of_month.to_time + 8.hours,first_of_month.to_time + 9.hours)
    assert_not cron.in_range?(second_of_month.to_time + 8.hours,second_of_month.to_time + 9.hours)
  end

  test "#in_month?" do
    cron = crons(:at_8_on_february)
    february=Date.parse "February"
    march= Date.parse "March"

    assert cron.in_month?(february)
    assert_not cron.in_month?(march)

  end

  test "#in_range? with hour and month 2" do
    cron = crons(:at_8_on_february)
    february=Date.parse "February"
    march= Date.parse "March"

    assert cron.in_range?(february.to_time + 8.hours,february.to_time + 9.hours)
    assert_not cron.in_range?(march.to_time + 8.hours,march.to_time + 9.hours)

  end

  test "check_next_execution! on Monday" do

    cron = crons(:at_8_on_monday)
    date=Date.parse 'Monday'

    assert cron.check_next_execution!> date.to_time
    assert_equal cron.check_next_execution!.wday, 1
    assert_equal cron.check_next_execution!.hour, 8

  end

  test "check_next_execution! on 1st of month" do

    cron = crons(:at_8_on_1st_of_month)
    date=Date.today.at_beginning_of_month

    assert cron.check_next_execution!> date.to_time
    assert_equal cron.check_next_execution!.hour, 8
    assert_equal cron.check_next_execution!.mday, 1
    assert cron.check_next_execution!.month>=date.month

  end

  test "check_next_execution! at 8 on February" do

    cron = crons(:at_8_on_february)
    date=Date.parse 'February'
    date=date.prev_month.at_end_of_month

    assert cron.check_next_execution!> date.to_time
    assert_equal cron.check_next_execution!.month, 2
    assert cron.check_next_execution!.month>date.month
    assert_equal cron.check_next_execution!.hour, 8

  end

  test "next_execution" do
    cron = crons(:at_8_on_monday)
    cron.save
    next_execution= cron.next_execution
    assert_not_nil next_execution
    cron.update(day_of_week: 2)
    cron.reload
    second_next_execution= cron.next_execution
    assert_not_equal second_next_execution, next_execution
    cron.update(day_of_week: 1)
    cron.reload
    assert next_execution, cron.next_execution

  end

end
