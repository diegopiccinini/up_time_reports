class ReportSaveDailyDataJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(date)
    ActiveRecord::Base.connection_pool.with_connection do

      message("Starting reports:",2,2)

      Report.start date

      Report.started(date).each do |r|
        message "Starting report for: #{r.vpc.name}"
      end

      message "Getting Performances from Pingdom",2,2

      Report.save_performances date

      Report.performances_saved_total(date).each do |r|
        message "#{r.vpc.name}: avgresponse: #{r.avgresponse}, status: #{r.status}"
      end

      message "Getting Outages from Pingdom",2,2

      Report.save_outages date

      Report.outages_saved_total(date).each do |r|
        message "#{r.vpc.name}: uptime: #{r.uptime}, downtime: #{r.downtime}, unmonitored: #{r.unmonitored}, status: #{r.status}"
      end

    end

  end

  def message(text,lines_before=0,lines_after=0)

    unless Rails.env == 'test'
      text="\n" * lines_before + text + "\n" * lines_after
      puts text
    end
  end

end
