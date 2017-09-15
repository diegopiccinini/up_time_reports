class Report < ApplicationRecord

  acts_as_paranoid

  belongs_to :vpc

  validates :status, presence: true
  validates :start_date, presence: true
  validate :validate_period
  validate :validate_resolution

  PERIODS = %w(day week month year)
  RESOLUTIONS =  %w(hour day week month)

  scope :daily, -> (date) { where( period: 'day', start_date: date ) }
  scope :started, -> (date) { daily(date).where( status: 'start' ) }

  def self.server_time
    Pingdom::ServerTime.time
  end

  def self.start date
    date= date.to_date

    self.daily( date ).delete_all

    Vpc.update_from_checks

    Vpc.all.each do |vpc|
      self.create  vpc: vpc, period: 'day', start_date: date, resolution: 'hour', status: 'start' , from: date.to_time, to: ((date + 1).to_time - 1)
    end

  end


  private

  def validate_period
    validate_inclusion :period, PERIODS
  end

  def validate_resolution
    validate_inclusion :resolution, RESOLUTIONS
  end

end
