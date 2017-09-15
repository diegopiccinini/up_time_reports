class Report < ApplicationRecord
  acts_as_paranoid

  belongs_to :vpc

  validates :status, presence: true
  validates :start_date, presence: true
  validates :period, inclusion: { in: %w(day week month year), message: "%{value} is not a valid period" }
  validates :resolution, inclusion: { in: %w(hour day week month), message: "%{value} is not a valid resolution" }


  def self.server_time
    Pingdom::ServerTime.time
  end


end
