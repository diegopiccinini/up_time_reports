require 'test_helper'

class VpcReportBuilderTrheeTest < ActiveSupport::TestCase

  setup do
    @three= VpcReportBuilder.new(reports(:three))
  end


  test "#spreadsheet_name" do
    report=reports(:three)
    assert @three.spreadsheet_name.include?(report.vpc.name)
    assert @three.spreadsheet_name.include?(report.vpc.hostname)
    assert @three.spreadsheet_name.include?(report.period.capitalize)
    assert @three.spreadsheet_name.include?(report.resolution.capitalize)
    assert @three.spreadsheet_name.include?(report.start_date.to_s)
  end

  test "#metadata" do
    assert_equal @three.metadata[:title],@three.spreadsheet_name
  end

  test "#data" do
    assert_kind_of Array, @three.data[:rows]
  end

  test "#build three report" do
    build_asserts @three, 24
  end

end
