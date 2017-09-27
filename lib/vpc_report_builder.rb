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
    rows = [[resolution.capitalize,'Outages', 'Downtime', 'Uptime', 'real uptime', 'Adjusted Outages', 'Adjusted Downtime', 'Adjusted Uptime']]
    rows+= report.performances.order(:starttime).map do |p|
      p.row
    end
    data[:rows]=rows
  end

end
