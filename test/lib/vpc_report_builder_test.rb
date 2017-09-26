require 'test_helper'

class VpcReportBuilderTest < ActiveSupport::TestCase

  setup do
    @one= VpcReportBuilder.new(reports(:one))
    @two= VpcReportBuilder.new(reports(:two))
  end

  test "#period" do
    assert_equal @one.period, 'daily'
    assert_equal @two.period, 'weekly'
  end

  test "#spreadsheet_name" do
    report=reports(:one)
    assert @one.spreadsheet_name.include?(report.vpc.name)
    assert @one.spreadsheet_name.include?(report.resolution)
    assert @one.spreadsheet_name.include?(report.start_date.to_s)
  end

  test "#metadata" do
    assert_equal @one.metadata[:title],@one.spreadsheet_name
  end

  test "#data" do
    assert_kind_of Array, @one.data[:rows]
  end

end
