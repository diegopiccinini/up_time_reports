require 'test_helper'

class VpcReportBuilderTest < ActiveSupport::TestCase

  def build_report_data report
    from =report.from.to_i
    to = report.to.to_i
    resolution= report.resolution
    outage_build_data(report.vpc.id,from,to)[:summary][:states].each do |outage|

      report.outages.create to_time( outage, [:timefrom, :timeto])
    end
    performance_build_data(report.vpc.id, from,to,resolution)[:summary][resolution.pluralize.to_sym].each do |performance|
      report.performances.create to_time(performance, [:starttime])
    end
  end

  def to_time hash, keys
    hash.each_pair do |key, value|
      hash[key]= Time.at(value) if keys.include?key
    end
    hash
  end

  setup do
    @three= VpcReportBuilder.new(reports(:three))
    @two= VpcReportBuilder.new(reports(:two))
    build_report_data reports(:two)
  end

  test "#periodically" do
    assert_equal @three.periodically, 'daily'
    assert_equal @two.periodically, 'weekly'
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
    @two.build
    assert_equal @two.data[:rows].count, 8
  end
end
