class ReportGeneratorJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(date:, period: 'day', resolution: 'hour', cron: nil)

    history= History.free

    if history

      ActiveRecord::Base.connection_pool.with_connection do

        History.start "Starting #{self.class.name} on #{date}, #{period} period and #{resolution} resolution", cron: cron

        history= History.execution(cron: cron) do

          global_report=GlobalReport.start date: date , period: period, resolution: resolution

          if resolution=='month'
            global_report.save_year_outages
          else
            global_report.save_performances
            global_report.save_outages
          end

        end


      end

    elsif cron
      cron.update(status: 'enqueue')
    end

    history

  end


end
