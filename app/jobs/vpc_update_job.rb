class VpcUpdateJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(cron: nil)

    history= History.free

    ActiveRecord::Base.connection_pool.with_connection do

      History.start "Starting #{self.class.name} on #{Time.now}", cron: cron

      Vpc.update_from_checks

      history = History.finish

    end if history

    history

  end

end
