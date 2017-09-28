class VpcUpdateJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  def perform(cron: nil)

    history= History.free

    if history
      ActiveRecord::Base.connection_pool.with_connection do

        History.start "Starting #{self.class.name} on #{Time.now}", cron: cron

        history= History.execution do
          Vpc.update_from_checks
        end

      end
    elsif cron
      cron.update(status: 'enqueue')
    end

    history

  end

end
