require 'test_helper'

class ReportValidationsTest < ActiveSupport::TestCase

  setup do
    @report = Report.new
  end


  test "should has a vpc" do

    assert_not @report.valid?
    assert @report.errors.keys.include?(:vpc)

    @report.vpc= vpcs(:one)
    @report.valid?
    assert_not @report.errors.keys.include?(:vpc)

  end

  test "should has a global_report" do

    assert_not @report.valid?
    assert @report.errors.keys.include?(:global_report)

    @report.global_report= global_reports(:one)
    @report.valid?
    assert_not @report.errors.keys.include?(:global_report)

  end


  test "should be valid" do
    @report.vpc = vpcs(:one)
    @report.global_report = global_reports(:one)
    @report.status = 'start'
    assert @report.valid?
  end

end
