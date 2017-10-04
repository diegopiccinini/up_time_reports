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

  def totals_asserts builder

    totals = builder.data[:totals]
    assert_kind_of Array, totals
    assert totals[builder.index('Uptime')]>0
    assert_equal totals[builder.index('Uptime')], builder.report.outage_uptime
    assert totals[builder.index('Downtime')]>0
    assert_equal totals[builder.index('Downtime')], builder.report.outage_downtime
    assert totals[builder.index('Unknown')]>0
    assert_equal totals[builder.index('Unknown')], builder.report.outage_unknown
    assert_equal totals[builder.index('Outages')], builder.report.incidents
    assert_equal totals[builder.index('Adjusted Outages')], builder.report.adjusted_incidents

    assert totals[builder.index('Uptime %')].to_f < 100.0
    assert totals[builder.index('Uptime %')].to_f > 40.0
    assert totals[builder.index('Adjusted Uptime %')].to_f >=  totals[builder.index('Uptime %')].to_f
    assert totals[builder.index('Adjusted Outages')] <=  totals[builder.index('Outages')]

  end

  def build_asserts builder, total
    builder.build
    assert_equal builder.data[:rows].count, total
    totals_asserts builder
  end

  test "#build three report" do
    build_asserts @three, 24
  end

  test "#build two report" do
    build_asserts @two, 7
  end

  test "#build month_daily report" do
    build_asserts @month_daily, Date.today.prev_month.at_end_of_month.day
  end

  test "#build month_weekly report" do
    build_asserts @month_weekly, 4
  end

  test "#build year_montly report" do
    build_asserts @year_monthly, 12
  end

  test "#build json ready" do
    [@three,@two,@month_daily,@month_weekly,@year_monthly].each { |x| x.build }
    assert_equal Report.json_ready.count, 5
  end

  test "#outages_by_month" do
    assert_equal @year_monthly.outages_by_month.count, 12
  end
end
