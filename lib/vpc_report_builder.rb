class VpcReportBuilder

  attr_accessor :report, :data

  def initialize report
    @report = report
    @data= { metadata: { title: spreadsheet_name }, rows: [] }
  end

  def metadata
    data[:metadata]
  end

  def spreadsheet_name
    "#{vpc.name} (#{vpc.hostname}) #{period} report by #{report.resolution} resolution, on #{report.start_date.to_s}"
  end

  def vpc
    report.vpc
  end

  def resolution
    report.resolution
  end

  def period
    report.period
  end

  def build
    header = [[resolution.capitalize,'Outages', 'Downtime','Unknown','Uptime','Real Uptime', 'Adjusted Outages', 'Adjusted Downtime', 'Adjusted Uptime', 'AVG Response']]
    data[:rows]= header + rows
    report.status = 'JSON ready'
    report.data = data.to_json
    report.uptime = report.outage_uptime
    report.downtime = report.outage_downtime
    report.unknown = report.outage_unknown
    report.adjusted_downtime= report.outage_adjusted_downtime
    report.avg_response = resolution=='month' ? report.average_avgresponse : report.performance_avgresponse

    report.save
  end

  def rows
    if resolution=='month'
      outages_by_month
    else
      report.performances.order(:starttime).map { |p| p.row }
    end
  end

  def outages_by_month

    from=report.from
    1.upto(12).map do |m|
      to=from.next_month

      interval= to.to_i - from.to_i
      total_uptime=report.outages.up(from,to).sum { |o| o.interval }

      outages= report.outages.down(from,to).count
      downtime=report.outages.down(from,to).sum do |outage|
        outage.interval / 60
      end

      unknown=report.outages.unknown(from,to).sum do |outage|
        outage.interval / 60
      end

      real_downtime=report.outages.down(from,to).sum { |outage| outage.interval }
      uptime= format("%.3f",total_uptime * 100.0 / interval)
      real_uptime=percent real_downtime, interval
      adjusted_outages= report.outages.down(from,to).adjusted.count

      adjusted_downtime= report.outages.down(from,to).adjusted.sum do |outage|
        outage.interval / 60
      end

      adjust_uptime = percent (adjusted_downtime * 60), interval
      avgresponse=report.averages.by_period(from,to).sum { |a| a.avgresponse }

      from=to
      [m, outages, downtime, unknown, uptime, real_uptime, adjusted_outages, adjusted_downtime, adjust_uptime, avgresponse]
    end
  end

  def percent partial_time , under
    n = (under.to_f - partial_time.to_f) * 100.0 / under.to_f
    format("%.3f", n )
  end

  def adjust_interval
    GlobalSetting.adjust_interval
  end

end
