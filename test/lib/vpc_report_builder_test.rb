require 'test_helper'

class VpcReportBuilderTest < ActiveSupport::TestCase

  setup do
    @three= VpcReportBuilder.new(reports(:three))
    @two= VpcReportBuilder.new(reports(:two))
  end

  test "#period" do
    assert_equal @three.period, 'daily'
    assert_equal @two.period, 'weekly'
  end

  test "#spreadsheet_name" do
    report=reports(:three)
    assert @three.spreadsheet_name.include?(report.vpc.name)
    assert @three.spreadsheet_name.include?(report.vpc.hostname)
    assert @three.spreadsheet_name.include?(report.resolution)
    assert @three.spreadsheet_name.include?(report.start_date.to_s)
  end

  test "#metadata" do
    assert_equal @three.metadata[:title],@three.spreadsheet_name
  end

  test "#data" do
    assert_kind_of Array, @three.data[:rows]
  end

  test "#build" do
    @three.build
    assert_equal @three.data[:rows].count, 25
  end
end
