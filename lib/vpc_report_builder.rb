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
    data[:header] = header
    data[:rows]= rows
    data[:totals]= totalize data[:rows]
    report.status = 'JSON ready'
    report.data = data.to_json
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

  def cols
    header.size
  end

  def rows
    if resolution=='month'
      outages_by_month
    else
      performance_rows
    end
  end

  def totalize data_rows
    data_rows=data_rows.reject do |r|
      r[index('Uptime')]=='-'
    end
    outages=data_rows.sum { |r| r[index('Outages')] }
    downtime=data_rows.sum { |r| r[index('Downtime')] }
    unknown=data_rows.sum { |r| r[index('Unknown')] }
    uptime=data_rows.sum { |r| r[index('Uptime')] }
    monitored = downtime + uptime
    uptime_percentage= monitored>0 ? (uptime * 100 / monitored) : 0
    uptime_percentage = percentage_format uptime_percentage

    adj_outages=data_rows.sum { |r| r[index('Adjusted Outages')] }
    adj_downtime=data_rows.sum { |r| r[index('Adjusted Downtime')] }
    adj_uptime=data_rows.sum { |r| r[index('Adjusted Uptime')] }
    adj_monitored = adj_downtime + adj_uptime
    adj_uptime_percentage= adj_monitored>0 ? (adj_uptime * 100 / adj_monitored) : 0
    adj_uptime_percentage = percentage_format adj_uptime_percentage

    avg_response = data_rows.sum { |r| r[index('AVG Response')] * r[index('Uptime')] }
    avg_response = uptime>0 ? avg_response / uptime : 0

    [data_rows.count,outages, downtime, unknown, uptime, uptime_percentage,adj_outages, adj_downtime, adj_uptime, adj_uptime_percentage, avg_response ]
  end

  def index field
    header.index(field)
  end

  def outages_by_month

    from=report.from
    1.upto(12).map do |m|
      to=from.next_month
      if report.outages.by_period(from,to).count> 0
        row = row_by_outages(m,from,to)
      else
        row = [m] + ['-'] * (cols - 1)
      end
      from=to
      row
    end

  end

  def row_by_outages resolution_unit, from, to

    outages= report.outages.down(from,to).count

    uptime=report.outages.up(from,to).sum { |o| o.interval  }

    downtime=report.outages.down(from,to).sum { |o| o.interval }

    monitored = uptime + downtime

    unknown=report.outages.unknown(from,to).sum { |o| o.interval }

    uptime_percentage= monitored>0 ? (uptime * 100.0 / monitored ) : 0.0

    uptime_percentage= percentage_format uptime_percentage

    adjusted_outages= report.outages.down(from,to).adjusted.count

    adjusted_downtime= report.outages.down(from,to).adjusted.sum { |o| o.interval }

    adjusted_uptime = uptime + (downtime - adjusted_downtime)

    adjusted_monitored = adjusted_uptime + adjusted_downtime

    adjusted_uptime_percentage= adjusted_monitored>0 ? (adjusted_uptime * 100.0 / adjusted_monitored ) : 0.0

    adjusted_uptime_percentage=percentage_format  adjusted_uptime_percentage

    avgresponse=report.averages.by_period(from,to).sum { |a| a.avgresponse }

    [resolution_unit, outages, downtime, unknown, uptime, uptime_percentage, adjusted_outages, adjusted_downtime, adjusted_uptime, adjusted_uptime_percentage, avgresponse]

  end

  def percentage_format p
    format("%.3f", p )
  end

  def performance_rows
    report.performances.order(:starttime).map { |p| row_by_performance p }
  end

  def row_by_performance performance

    resolution_unit = performance.unit_step

    outages = performance.incidents

    uptime  = performance.uptime

    downtime= performance.downtime

    monitored = uptime + downtime

    unknown = performance.unmonitored

    uptime_percentage= monitored>0 ? (uptime * 100.0 / monitored ) : 0.0

    uptime_percentage= percentage_format uptime_percentage

    adjusted_outages= performance.adjusted_incidents

    adjusted_downtime= performance.adjusted_downtime

    adjusted_uptime = uptime + (downtime - adjusted_downtime)

    adjusted_monitored = adjusted_uptime + adjusted_downtime

    adjusted_uptime_percentage= adjusted_monitored>0 ? (adjusted_uptime * 100.0 / adjusted_monitored ) : 0.0

    adjusted_uptime_percentage= percentage_format adjusted_uptime_percentage

    avgresponse=performance.avgresponse

    [resolution_unit, outages, downtime, unknown, uptime, uptime_percentage, adjusted_outages, adjusted_downtime, adjusted_uptime, adjusted_uptime_percentage, avgresponse]

  end

end
