require 'test_helper'

class VpcReportBuilderTest < ActiveSupport::TestCase

  def build_report_data report
    from =report.from.to_i
    to = report.to.to_i
    resolution= report.resolution
    outage_build_data(report.vpc.id,from,to,resolution)[:summary][:states].each do |outage|
      report.outages.create to_time( outage, [:timefrom, :timeto])
    end
    performance_build_data(report.vpc.id, from,to,resolution)[:summary][resolution.pluralize.to_sym].each do |performance|
      report.performances.create to_time(performance, [:starttime])
    end
  end

  def build_year_report_data report
    from =report.from
    1.upto(12) do |m|
      to = from.next_month
      average= { 'up' => 0 , 'down' => 0 , 'unknown' => 0 }
      outage_build_data(report.vpc.id,from.to_i,to.to_i, 'day')[:summary][:states].each do |outage|
        o=to_time( outage, [:timefrom, :timeto])
        average[o[:status]]+= o[:timeto].to_i - o[:timefrom].to_i
        report.outages.create o
      end
      report.averages.create from: from, to: to, avgresponse: rand(1000), totalup: average['up'] , totaldown: average['down'], totalunknown: average['unknown']
      from=to
    end
  end

  def to_time hash, keys
    hash.each_pair do |key, value|
      hash[key]= Time.at(value) if keys.include?key
    end
    hash
  end

  def by_report key
    build_report_data reports(key)
    VpcReportBuilder.new(reports(key))
  end

  setup do
    @three= VpcReportBuilder.new(reports(:three))
    @two=by_report :two
    @month_daily= by_report :month_daily
    @month_weekly= by_report :month_weekly
    build_year_report_data reports(:year_monthly)
    @year_monthly=VpcReportBuilder.new(reports(:year_monthly))
  end


  test "#spreadsheet_name" do
    report=reports(:three)
    assert @three.spreadsheet_name.include?(report.vpc.name)
    assert @three.spreadsheet_name.include?(report.vpc.hostname)
    assert @three.spreadsheet_name.include?(report.period)
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

    @month_daily.build
    assert_equal @month_daily.data[:rows].count, Date.today.prev_month.at_end_of_month.day + 1

    @month_weekly.build
    assert @month_weekly.data[:rows].count, 4

    @year_monthly.build
    assert @year_monthly.data[:rows].count, 13

    assert_equal Report.json_ready.count, 5

  end

  test "#outages_by_month" do
    assert_equal @year_monthly.outages_by_month.count, 12
  end
end
