class ReportBodyJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(cron: nil)
    history= History.free

    if history

      ActiveRecord::Base.connection_pool.with_connection do

        History.start "Starting #{self.class.name}", cron: cron

        history= History.execution do

          GlobalReport.outages_saved.each do |global_report|
            global_report.vpc_reports_build
          end

        end

      end

    elsif cron
      cron.update(status: 'enqueue')
    end

    history
  end
end
