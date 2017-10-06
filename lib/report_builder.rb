class ReportBuilder

  attr_accessor :report, :data

  def initialize report
    @report = report
    @data= { metadata: { title: spreadsheet_name }, rows: [] }
  end

  def metadata
    data[:metadata]
  end

  def spreadsheet_name
    report.name
  end

  def resolution
    report.resolution
  end

  def period
    report.period
  end

  def build_data
    data[:header] = header
    data[:rows]= rows
    data[:formatted_rows] = format_rows data[:rows]
    data[:totals]= totalize data[:rows]
    data[:formatted_totals] = format_row data[:totals]
    data.to_json
  end

  def build
    report.status = 'JSON ready'
    report.data = build_data
    report.save
  end

  def cols
    header.size
  end


  def format_rows data_rows
    data_rows.map do |r|
      format_row r
    end
  end

  def format_row r
    r.map.with_index do |value, i|
      if value=='-'
        {value: value, formatted: value, style: '' }
      else
        { value: value, formatted: format_column(i,value), style: style_column(i,value) }
      end
    end
  end

  def format_column i, value
    case header[i]
    when 'Downtime','Unknown', 'Uptime', 'Adjusted Downtime', 'Adjusted Uptime'
      value / 60
    when 'Uptime %', 'Adjusted Uptime %'
      percentage_format value
    else
      value
    end
  end

  def style_column i, value
    case header[i]
    when 'Uptime %', 'Adjusted Uptime %'
      if value < 99.95
        'red'
      elsif value < 100.00
        'green'
      else
        'blue'
      end
    when 'VPC', 'Site'
      'tdleft'
    else
      'tdcenter'
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
    uptime_percentage= monitored>0 ? (uptime * 100.0 / monitored) : 0

    adj_outages=data_rows.sum { |r| r[index('Adjusted Outages')] }
    adj_downtime=data_rows.sum { |r| r[index('Adjusted Downtime')] }
    adj_uptime=data_rows.sum { |r| r[index('Adjusted Uptime')] }
    adj_monitored = adj_downtime + adj_uptime
    adj_uptime_percentage= adj_monitored>0 ? (adj_uptime * 100.0 / adj_monitored) : 0

    avg_response = data_rows.sum { |r| r[index('AVG Response')] * r[index('Uptime')] }
    avg_response = uptime>0 ? avg_response / uptime : 0

    ["rows: #{data_rows.count}",outages, downtime, unknown, uptime, uptime_percentage,adj_outages, adj_downtime, adj_uptime, adj_uptime_percentage, avg_response ]
  end

  def index field
    header.index(field)
  end

  def percentage_format p
    format("%.3f %", p )
  end

end
