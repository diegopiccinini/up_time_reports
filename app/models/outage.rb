class Outage < ApplicationRecord
  belongs_to :vpc

  scope :by_dates, -> (from,to) { where( timefrom: from..to) }
  scope :up, -> (from,to) { by_dates(from,to).where(status: 'up') }
  scope :down, -> (from,to) { by_dates(from,to).where(status: 'down') }

end
