class Report < ApplicationRecord

  acts_as_paranoid

  belongs_to :vpc

  validates :status, presence: true
  validates :start_date, presence: true
  validate :validate_period
  validate :validate_resolution
  has_many :performances, :dependent => :delete_all
  has_many :outages, :dependent => :delete_all

  PERIODS = %w(day week month year)
  RESOLUTIONS =  %w(hour day week)

  scope :daily, -> (date) { where( period: 'day', start_date: date ) }
  scope :started, -> (date) { daily(date).where( status: 'start' ) }
  scope :performances_saved, -> (date) { daily(date).where( status: 'performances saved' ) }
  scope :performances_saved_total, -> (date) { daily(date).where( "status LIKE ?", 'performances saved%' ) }
  scope :outages_saved, -> (date) { daily(date).where( status: 'outages saved' ) }
  scope :outages_saved_total, -> (date) { daily(date).where( "status LIKE ?", 'outages saved%' ) }


  def self.server_time
    Pingdom::ServerTime.time
  end

  def self.start date, period: 'day', resolution: 'hour'

    History.write "** Starting #{period} reports on #{date}",2,2

    self.daily( date ).destroy_all

    Vpc.update_from_checks

    Vpc.all.each do |vpc|
      self.create  vpc: vpc, period: period, start_date: date, resolution: resolution, status: 'start' , from: date.to_time, to: ((date + 1).to_time)
    end

  end

  def self.save_performances date
    History.write "** Saving performances",2,2
    step filter_scope: :started, update_method: :update_performances, status: 'performances saved', date: date
  end

  def self.save_outages date
    History.write "** Saving outages",2,2
    step filter_scope: :performances_saved, update_method: :update_outages, status: 'outages saved', date: date
  end

  def self.step filter_scope:, update_method: , status: , date:
    self.send(filter_scope,date).each do |report|
      begin
        History.write "\t#{update_method} on #{report.vpc.name}"
        report.send(update_method)
        report.status = status
      rescue
        report.status = status + ' error'
      end
      report.save
    end
  end

  def update_performances
    performances.delete_all
    performance=Pingdom::SummaryPerformance.find vpc.id, from: from, to: to, includeuptime: true, resolution: resolution
    performance.hours.each do |h|
      performances.create starttime: h.starttime, avgresponse: h.avgresponse, uptime: h.uptime, downtime: h.downtime, unmonitored: h.unmonitored
    end
  end

  def update_outages
    outages.delete_all
    outage=Pingdom::SummaryOutage.find vpc.id, from: from, to: to
    outage.states.each do |s|
      outages.create status: s.status, timefrom: s.timefrom, timeto: s.timeto
    end
  end

  def uptime
    outages.up(from,to).all.sum { |x| x.interval }
  end

  def downtime
    outages.down(from,to).all.sum { |x| x.interval }
  end

  def unmonitored
    outages.unknown(from,to).all.sum { |x| x.interval }
  end

  def performances_uptime
    performances.sum(:uptime)
  end

  def performances_downtime
    performances.sum(:downtime)
  end

  def performances_unmonitored
    performances.sum(:unmonitored)
  end

  def avgresponse
    performances.count>0 ? performances.total_avg/performances.count : 0
  end

  private

  def validate_period
    validate_inclusion :period, PERIODS
  end

  def validate_resolution
    validate_inclusion :resolution, RESOLUTIONS
  end

end
