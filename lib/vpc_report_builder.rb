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
    "#{vpc.name} (#{vpc.hostname}) #{periodically} report by #{report.resolution} resolution, on #{report.start_date.to_s}"
  end

  def periodically
    case period
    when 'day'
      'daily'
    else
      period + 'ly'
    end
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

    data[:rows]= case resolution
                 when 'hour'
                   build_vpc_day_by_hour
                 end
  end

  private

  def percent n
    n = (1.send(resolution).to_f - n.to_f) * 100.0 / 1.send(resolution).to_f
    format("%.3f%", n )
  end

  def build_vpc_day_by_hour
    rows = [['Hour','Outages', 'Downtime', 'Uptime', 'real uptime', 'Adjusted Outages', 'Adjusted Downtime', 'Adjusted Uptime']]
    rows+= report.performances.order(:starttime).map do |p|
      downtime = p.downtime / 60
      uptime_percent= percent( downtime.to_f * 60.0 )
      real_uptime_percent= percent( p.downtime.to_f )

      adjusted_downtime = p.downtime<180 ? 0 : p.downtime
      adjusted_uptime= percent( adjusted_downtime.to_f * 60.0 )

      [p.starttime.hour, p.incidents, downtime , uptime_percent, real_uptime_percent, p.adjusted_incidents, adjusted_downtime, adjusted_uptime]
    end
    rows
  end
end
