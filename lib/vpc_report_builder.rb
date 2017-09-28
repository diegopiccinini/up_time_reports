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
    header = [[resolution.capitalize,'Outages', 'Downtime', 'Uptime', 'real uptime', 'Adjusted Outages', 'Adjusted Downtime', 'Adjusted Uptime']]
    data[:rows]= header + rows
    report.status = 'JSON ready'
    report.data = data.to_json
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

      outages= report.outages.down(from,to).count
      downtime=report.outages.down(from,to).sum do |outage|
        outage.interval / 60
      end

      real_downtime=report.outages.down(from,to).sum { |outage| outage.interval }
      uptime=percent (downtime * 60) , interval
      real_uptime=percent real_downtime, interval
      adjusted_outages= report.outages.down(from,to).count do |outage|
        outage.interval < adjust_interval
      end

      adjusted_downtime= report.outages.down(from,to).sum do |outage|
        outage.interval < adjust_interval ? 0 : (outage.interval / 60)
      end
      adjust_uptime = percent (adjusted_downtime * 60), interval

      from=to
      [m, outages, downtime, uptime, real_uptime, adjusted_outages, adjusted_downtime, adjust_uptime]
    end
  end

  def percent partial_time , under
    n = (partial_time.to_f) * 100.0 / under.to_f
    format("%.3f%", n )
  end

  def adjust_interval
    @adjust_interval||=GlobalSetting.get('adjust_interval')[:value]
    @adjust_interval
  end

end
