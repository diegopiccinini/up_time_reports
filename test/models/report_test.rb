require 'test_helper'

class ReportTest < ActiveSupport::TestCase

  test "#server_time" do

    server_time =Report.server_time

    assert_kind_of Time, server_time
    assert (Time.new - server_time) < 1.0

  end

  test "should has a vpc" do

    report= Report.new
    assert_not report.valid?
    assert report.errors.keys.include?(:vpc)

    report.vpc= vpcs(:one)
    report.valid?
    assert_not report.errors.keys.include?(:vpc)

  end

  test "should validate precense_of status, start_date" do

    report= Report.new
    assert_not report.valid?
    assert report.errors.keys.include?(:status)
    assert report.errors.keys.include?(:start_date)

    report.status = 'start'
    report.valid?
    assert_not report.errors.keys.include?(:status)
    report.start_date = 1.day.ago
    report.valid?
    assert_not report.errors.keys.include?(:start_date)
  end

  test "should has a valid period" do

    report= Report.new

    assert_not report.valid?
    assert report.errors.keys.include?(:period)

    report.period = '2 years'
    assert_not report.valid?
    assert report.errors.keys.include?(:period)
    %w(day week month year).each do |period|
      report.period = period
      report.valid?
      assert_not report.errors.keys.include?(:period)
    end

  end

  test "should has a valid resolution" do

    report= Report.new

    assert_not report.valid?
    assert report.errors.keys.include?(:resolution)

    report.resolution = 'year'
    assert_not report.valid?
    assert report.errors.keys.include?(:resolution)

    %w(hour day week month).each do |resolution|
      report.resolution = resolution
      report.valid?
      assert_not report.errors.keys.include?(:resolution)
    end

  end

  test "should be valid" do
    report= Report.new
    report.vpc = vpcs(:one)
    report.status = 'start'
    report.start_date = 1.day.ago
    report.period = 'day'
    report.resolution = 'hour'
    assert report.valid?
  end


end
