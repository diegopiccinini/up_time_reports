class GlobalReportBuilder

  attr_accessor :report, :data

  def initialize report
    @report = report
    @data= { metadata: { title: spreadsheet_name }, rows: [] }
  end

  def metadata
    data[:metadata]
  end

  def spreadsheet_name
    "#Global #{period.capitalize} Report by #{resolution} resolution, on #{report.start_date.to_s}"
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
    report.save
  end

  def header
    ['VPC', 'Site',resolution.capitalize,'Outages', 'Downtime','Unknown','Uptime','Uptime %', 'Adjusted Outages', 'Adjusted Downtime', 'Adjusted Uptime', 'Adjusted Uptime %', 'AVG Response']
  end

  def cols
    header.size
  end

  def rows
    global_rows=[]
    report.reports.json_ready.each do |r|
      global_rows+= r.data_hash[:rows].map do |data_row|
        [r.vpc.name, r.vpc.hostname] + data_row
      end
    end
    global_rows.sort do |x,y|
      if resolution =='hour'
        format("%02d",x[2]) + x[0].to_s + x[1].to_s <=> format("%02d",y[2]) + y[0].to_s + y[1].to_s
      else
        x[2].to_s + x[0].to_s + x[1].to_s <=> y[2].to_s + y[0].to_s + y[1].to_s
      end

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
    uptime_percentage = percentage_format uptime_percentage

    adj_outages=data_rows.sum { |r| r[index('Adjusted Outages')] }
    adj_downtime=data_rows.sum { |r| r[index('Adjusted Downtime')] }
    adj_uptime=data_rows.sum { |r| r[index('Adjusted Uptime')] }
    adj_monitored = adj_downtime + adj_uptime
    adj_uptime_percentage= adj_monitored>0 ? (adj_uptime * 100.0 / adj_monitored) : 0
    adj_uptime_percentage = percentage_format adj_uptime_percentage

    avg_response = data_rows.sum { |r| r[index('AVG Response')] * r[index('Uptime')] }
    avg_response = uptime>0 ? avg_response / uptime : 0

    ["rows: #{data_rows.count}",'-' ,'-',outages, downtime, unknown, uptime, uptime_percentage,adj_outages, adj_downtime, adj_uptime, adj_uptime_percentage, avg_response ]
  end

  def index field
    header.index(field)
  end

  def percentage_format p
    format("%.3f", p )
  end

end
