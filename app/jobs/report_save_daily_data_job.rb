class ReportSaveDailyDataJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(date)

    Report.start date
    Report.save_performance date
    Report.save_outage date

  end
end
