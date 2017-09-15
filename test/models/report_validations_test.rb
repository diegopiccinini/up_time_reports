require 'test_helper'

class ReportValidationsTest < ActiveSupport::TestCase

  setup do
    @report = Report.new
  end

  test "#valid_periods" do
    assert_not Report::PERIODS.empty?
  end

  test "#valid_resolutions" do
    assert_not Report::RESOLUTIONS.empty?
  end

  test "should has a vpc" do

    assert_not @report.valid?
    assert @report.errors.keys.include?(:vpc)

    @report.vpc= vpcs(:one)
    @report.valid?
    assert_not @report.errors.keys.include?(:vpc)

  end

  test "should validate precense_of status, start_date" do

    assert_not @report.valid?
    assert @report.errors.keys.include?(:status)
    assert @report.errors.keys.include?(:start_date)

    @report.status = 'start'
    @report.valid?
    assert_not @report.errors.keys.include?(:status)
    @report.start_date = 1.day.ago
    @report.valid?
    assert_not @report.errors.keys.include?(:start_date)
  end

  test "should has a valid period" do

    assert_not @report.valid?
    assert @report.errors.keys.include?(:period)

    @report.period = '2 years'
    assert_not @report.valid?
    assert @report.errors.keys.include?(:period)
    Report::PERIODS.each do |period|
      @report.period = period
      @report.valid?
      assert_not @report.errors.keys.include?(:period)
    end

  end

  test "should has a valid resolution" do

    assert_not @report.valid?
    assert @report.errors.keys.include?(:resolution)

    @report.resolution = 'year'
    assert_not @report.valid?
    assert @report.errors.keys.include?(:resolution)

    Report::RESOLUTIONS.each do |resolution|
      @report.resolution = resolution
      @report.valid?
      assert_not @report.errors.keys.include?(:resolution)
    end

  end

  test "should be valid" do
    @report.vpc = vpcs(:one)
    @report.status = 'start'
    @report.start_date = 1.day.ago
    @report.period = 'day'
    @report.resolution = 'hour'
    assert @report.valid?
  end

end
