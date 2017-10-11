require 'test_helper'

class VpcReportBuilderTest < ActiveSupport::TestCase

  def total_asserts builder, rows
    build_asserts builder, rows
    global=GlobalReportBuilder.new builder.report.global_report
    global.build
    assert_equal global.data[:rows].count, rows
  end


  test "#build two report" do
    builder=by_report :two
    total_asserts builder, 7
  end

  test "#build month_daily report" do
    builder=by_report :month_daily
    rows=Date.today.prev_month.at_end_of_month.day
    total_asserts builder, rows
  end

  test "#build month_weekly report" do
    builder=by_report :month_weekly
    total_asserts builder, 4
  end

  test "#build year_monthly report" do
    report=reports(:year_monthly)
    build_year_report_data report

    builder=VpcReportBuilder.new(report)
    builder.build

    total_asserts builder, 12
  end


end
