class Report < ApplicationRecord

  acts_as_paranoid

  belongs_to :vpc

  validates :status, presence: true
  validates :start_date, presence: true
  validate :validate_period
  validate :validate_resolution

  PERIODS = %w(day week month year)
  RESOLUTIONS =  %w(hour day week month)

  def self.server_time
    Pingdom::ServerTime.time
  end

  def self.start( date: , period: )

    raise "#{period} is not a valid period" unless PERIODS.include?(period)

    reports = 0

    self.where( period: period, start_date: date ).delete_all

    Vpc.update_from_checks

    Vpc.all.each do |vpc|
      reports+=1 if self.create( vpc: vpc, period: period, start_date: date, resolution: 'hour', status: __method__.to_s )
    end

    { reports: reports }
  end

  private

  def validate_period
    validate_inclusion :period, PERIODS
  end

  def validate_resolution
    validate_inclusion :resolution, RESOLUTIONS
  end

end
