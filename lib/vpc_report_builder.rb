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
    "#{report.vpc.name} #{period} report by #{report.resolution} resolution, on #{report.start_date.to_s}"
  end

  def period
    case report.period
    when 'day'
      'daily'
    else
      report.period + 'ly'
    end
  end

end
