class ReportSaveDailyDataJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(date)
    ActiveRecord::Base.connection_pool.with_connection do

      Report.start date

      Report.save_performances date

      Report.save_outages date

    end

  end


end
