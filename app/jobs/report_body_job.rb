class ReportBodyJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(cron: nil)
    history= History.free

    if history

      ActiveRecord::Base.connection_pool.with_connection do

        History.start "Starting #{self.class.name}", cron: cron

        history= History.execution do

          Report.where(status: 'outages saved').each do |report|
            report_builder=VpcReportBuilder.new report
            History.write "Build the #{report.vpc.name} #{report.period} report by #{report.resolution}"
            report_builder.build
          end

        end

      end

    elsif cron
      cron.update(status: 'enqueue')
    end

    history
  end
end
