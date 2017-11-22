class Outage < ApplicationRecord
  belongs_to :report

  scope :by_period, -> (from,to) { where("timefrom >= ? and timeto<= ?",from,to) }
  scope :up, -> (from,to) { by_period(from,to).where(status: 'up') }
  scope :down, -> (from,to) { by_period(from,to).where(status: 'down') }
  scope :unknown, -> (from,to) { by_period(from,to).where(status: 'unknown') }
  scope :adjusted, -> { where( "timeto >= timefrom + interval '?' second and status = ? ", GlobalSetting.adjust_interval,'down' ) }

  def interval
    (timeto - timefrom).to_i
  end

end
