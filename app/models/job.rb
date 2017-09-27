class Job < ApplicationRecord

  def run! cron
    result=case name
    when 'Initialize Daily Vpc Reports'
      ReportGeneratorJob.perform_now(Date.yesterday, cron: cron)
    when 'Initialize Weekly Vpc Reports'
      ReportGeneratorJob.perform_now(Date.parse('Monday').prev_week, period: 'week', resolution: 'day', cron: cron)
    when 'Initialize Monthly Vpc Reports with day Resolution'
      ReportGeneratorJob.perform_now(Date.today.prev_month.at_beginning_of_month, period: 'month', resolution: 'day', cron: cron)
    when 'Initialize Monthly Vpc Reports with week Resolution'
      date=Date.today.prev_month.at_beginning_of_month
      date-= 1 until date.wday=1 #beginning on monday
      ReportGeneratorJob.perform_now(date, period: 'month', resolution: 'day', cron: cron)
    when 'Initialize Yearly Vpc Reports with month Resolution'
      date=Date.today.prev_year.at_beginning_of_year
      ReportGeneratorJob.perform_now(date, period: 'year', resolution: 'month', cron: cron)
    when 'Vpc Update'
      VpcUpdateJob.perform_now(cron: cron)
    end
    result
  end

end
