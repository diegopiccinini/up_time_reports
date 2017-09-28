class ReportGeneratorJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(date, period: 'day', resolution: 'hour', cron: nil)

    history= History.free

    if history

      ActiveRecord::Base.connection_pool.with_connection do

        History.start "Starting #{self.class.name} on #{date}, #{period} period and #{resolution} resolution", cron: cron

        history= History.execution do

          Report.start date , period: period, resolution: resolution

          if resolution=='month'
            Report.save_year_outages date
          else
            Report.save_performances date, period
            Report.save_outages date, period
          end

        end


      end

    elsif cron
      cron.update(status: 'enqueue')
    end

    history

  end


end
