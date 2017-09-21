class ReportSaveDailyDataJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(date)
    ActiveRecord::Base.connection_pool.with_connection do

      History.start self.class.name

      Report.start date

      Report.save_performances date

      Report.save_outages date

      History.finish

    end

  end


end
