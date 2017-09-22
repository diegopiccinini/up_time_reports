class Job < ApplicationRecord

  def execution cron
    case name
    when 'Daily Vpc Reports'
      ReportGeneratorJob.perform_async(Date.today, cron: cron)
    when 'Weekly Vpc Reports'
      ReportGeneratorJob.perform_async(Date.parse('Monday').prev_week, period: 'week', resolution: 'day', cron: cron)
    when 'Monthly Vpc Reports'
      ReportGeneratorJob.perform_async(Date.today.prev_month.at_beginning_of_month, period: 'month', resolution: 'day', cron: cron)
    end
  end

end
