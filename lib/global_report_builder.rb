class GlobalReportBuilder < ReportBuilder

  def spreadsheet_name
    'Global ' + super
  end

  def header
    ['VPC', 'Site',resolution.capitalize,'Outages', 'Downtime','Unknown','Uptime','Uptime %', 'Adjusted Outages', 'Adjusted Downtime', 'Adjusted Uptime', 'Adjusted Uptime %', 'AVG Response']
  end

  def totalize data_rows
    totals = super data_rows
    [totals[0],'-','-']  + totals[1..-1]
  end

  def rows
    global_rows=[]
    report.reports.json_ready.each do |r|
      global_rows+= r.data_hash[:rows].map do |data_row|
        [r.vpc.name, r.vpc.hostname] + data_row
      end
    end
    global_rows.sort do |x,y|
      if %w(hour day month).include? resolution
        compare_number(x) <=> compare_number(y)
      else
        compare_date(x) <=> compare_date(y)
      end
    end
  end

  def compare_number x
    format("%02d",x[2]) + x[0].to_s + x[1].to_s
  end

  def compare_date x
    Date.parse(x[2]).strftime("%Y%m%d") + x[0].to_s + x[1].to_s
  end

end
