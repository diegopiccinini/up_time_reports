class Job < ApplicationRecord

  def execution cron
    case name
    when 'DailyVpcReports'
      ReportGeneratorJob.perform_async(Date.today, cron: cron)
    end
  end

end
