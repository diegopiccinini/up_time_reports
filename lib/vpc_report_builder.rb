class VpcReportBuilder < ReportBuilder

  def vpc
    report.vpc
  end

  def build
    report.status = 'JSON ready'
    report.data =  build_data
    report.uptime = report.outage_uptime
    report.downtime = report.outage_downtime
    report.unknown = report.outage_unknown
    report.adjusted_downtime= report.outage_adjusted_downtime
    report.avg_response = resolution=='month' ? report.average_avgresponse : report.performance_avgresponse

    report.save
  end

  def header
    [resolution.capitalize,'Outages', 'Downtime','Unknown','Uptime','Uptime %', 'Adjusted Outages', 'Adjusted Downtime', 'Adjusted Uptime', 'Adjusted Uptime %', 'AVG Response']
  end

  def rows
    if resolution=='month'
      outages_by_month
    else
      performance_rows
    end
  end

  def outages_by_month

    from=report.from
    r=1.upto(12).map do |m|
      to=from.next_month
      if report.outages.by_period(from,to).count> 0
        row = row_by_outages(m,from,to)
      else
        row = false
      end
      from=to
      row
    end

    r.select { |x| x }

  end

  def row_by_outages resolution_unit, from, to

    outages= report.outages.down(from,to).count

    uptime=report.outages.up(from,to).sum { |o| o.interval  }

    downtime=report.outages.down(from,to).sum { |o| o.interval }

    monitored = uptime + downtime

    unknown=report.outages.unknown(from,to).sum { |o| o.interval }

    uptime_percentage= ratio uptime, monitored

    adjusted_outages= report.outages.down(from,to).adjusted.count

    adjusted_downtime= report.outages.down(from,to).adjusted.sum { |o| o.interval }

    adjusted_uptime = uptime + (downtime - adjusted_downtime)

    adjusted_monitored = adjusted_uptime + adjusted_downtime

    adjusted_uptime_percentage= ratio adjusted_uptime , adjusted_monitored

    avgresponse=report.averages.by_period(from,to).sum { |a| a.avgresponse }

    [resolution_unit, outages, downtime, unknown, uptime, uptime_percentage, adjusted_outages, adjusted_downtime, adjusted_uptime, adjusted_uptime_percentage, avgresponse]

  end

  def performance_rows
    report.performances.where("starttime <= ?",report.to).order(:starttime).map { |p| row_by_performance p }
  end

  def row_by_performance performance

    resolution_unit = performance.unit_step

    outages = performance.incidents

    uptime  = performance.uptime

    downtime= performance.downtime

    monitored = uptime + downtime

    unknown = performance.unmonitored

    uptime_percentage= ratio uptime, monitored

    adjusted_outages= performance.adjusted_incidents

    adjusted_downtime= performance.adjusted_downtime

    adjusted_uptime = uptime + (downtime - adjusted_downtime)

    adjusted_monitored = adjusted_uptime + adjusted_downtime

    adjusted_uptime_percentage= ratio adjusted_uptime, adjusted_monitored

    avgresponse=performance.avgresponse

    [resolution_unit, outages, downtime, unknown, uptime, uptime_percentage, adjusted_outages, adjusted_downtime, adjusted_uptime, adjusted_uptime_percentage, avgresponse]

  end

end
