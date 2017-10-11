require 'test_helper'

class VpcReportBuilderTest < ActiveSupport::TestCase

  test "#build two report" do
    report=by_report :two
    build_asserts report, 7
  end

  test "#build month_daily report" do
    report=by_report :month_daily
    build_asserts report, Date.today.prev_month.at_end_of_month.day
  end

  test "#build month_weekly report" do
    report=by_report :month_weekly
    build_asserts report, 4
  end

  test "#build year_monthly report" do
    report=reports(:year_monthly)
    build_year_report_data report

    builder=VpcReportBuilder.new(report)
    builder.build

    build_asserts builder, 12
  end


end
