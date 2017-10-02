class Report < ApplicationRecord

  acts_as_paranoid

  belongs_to :vpc

  validates :status,:start_date, presence: true
  validate :validate_period
  validate :validate_resolution
  has_many :performances, :dependent => :delete_all
  has_many :outages, :dependent => :delete_all
  has_many :averages, :dependent => :delete_all

  PERIODS = %w(day week month year)
  RESOLUTIONS =  %w(hour day week month)

  scope :by_period, -> (period='day') { where( period: period ) }
  scope :by_date, -> (date) { where( start_date: date ) }
  scope :by_date_and_period, -> (date,period) { where( start_date: date, period: period ) }
  scope :daily, -> (date) { by_period.by_date(date) }

  scope :started, -> (date, period='day') { by_date_and_period(date,period).where( status: 'start') }
  scope :performances_saved, -> (date, period='day') do
    by_date_and_period(date,period).where( status: 'performances saved' )
  end
  scope :performances_saved_total, -> (date, period='day') do
    by_date_and_period(date,period).where( "status LIKE ?", 'performances saved%' )
  end
  scope :outages_saved, -> (date, period='day') { by_date_and_period(date,period).where( status: 'outages saved' ) }
  scope :outages_saved_total, -> (date, period='day') { by_date_and_period(date,period).where( "status LIKE ?", 'outages saved%' ) }
  scope :json_ready, -> { where( status: 'JSON ready') }


  def self.server_time
    Pingdom::ServerTime.time
  end

  def self.start date, period: 'day', resolution: 'hour'

    date = GlobalSetting.date_in_default_timezone date

    History.write "** Starting #{period} reports on #{date}",2,2

    self.by_date_and_period( date, period ).destroy_all

    to = case period
         when 'day'
           date.next_day
         when 'week'
           date.next_week
         when 'month'
           if resolution=='week'
             to = date.next_month.at_end_of_month
             to-=1 until to.wday==1
             GlobalSetting.date_in_default_timezone to
           else
             date.next_month
           end
         when 'year'
           date.next_year
         end

    Vpc.all.each do |vpc|
      self.create( vpc: vpc,
                  period: period,
                  start_date: date,
                  resolution: resolution,
                  status: 'start' ,
                  from: date.to_time,
                  to: to.to_time
                 )

    end

  end

  def self.save_performances date, period='day'
    History.write "** Saving performances",2,2
    step filter_scope: :started, update_method: :update_performances, status: 'performances saved', date: date, period: period
  end

  def self.save_outages date, period='day'
    History.write "** Saving outages",2,2
    step filter_scope: :performances_saved, update_method: :update_outages, status: 'outages saved', date: date, period: period
  end

  def self.save_year_outages date
    History.write "** Saving outages",2,2
    step filter_scope: :started, update_method: :update_year_outages, status: 'outages saved', date: date, period: 'year'
  end

  def self.step filter_scope:, update_method: , status: , date:, period:
    self.send(filter_scope,date,period).each do |report|
      begin
        History.write "\t#{update_method} on #{report.vpc.name}"
        report.send(update_method)
        report.status = status
      rescue
        History.write "\t#{update_method} error on #{report.vpc.name}", level: 'error'
        report.status = status + ' error'
      end
      report.save
    end
  end

  def update_performances
    performances.delete_all
    Pingdom::SummaryPerformance.params={}
    performance=Pingdom::SummaryPerformance.find vpc.id, from: from, to: to, includeuptime: true, resolution: resolution
    performance.send(resolution.pluralize).each do |h|
      if h.starttime<to
        performances.create starttime: h.starttime, avgresponse: h.avgresponse, uptime: h.uptime, downtime: h.downtime, unmonitored: h.unmonitored
      end
    end
  end

  def update_outages
    outages.delete_all
    Pingdom::SummaryOutage.params={}
    pingdom_outages=Pingdom::SummaryOutage.find vpc.id, from: from, to: to
    create_outages_from_pingdom pingdom_outages.states
  end

  def create_outages_from_pingdom states
    states.each do |s|
      outages.create status: s.status, timefrom: s.timefrom, timeto: s.timeto
    end
  end

  def create_averages_from_pingdom average
    averages.create(
      from: average.from,
      to: average.to,
      avgresponse: average.avgresponse,
      totalup: average.status.totalup,
      totaldown: average.status.totaldown,
      totalunknown: average.status.totalunknown
    )
  end

  def update_year_outages
    outages.delete_all
    averages.delete_all
    starting_at=from

    1.upto(12) do
      next_month=starting_at.next_month.at_beginning_of_month
      Pingdom::SummaryOutage.params={}
      pingdom_outages=Pingdom::SummaryOutage.find vpc.id, from: starting_at, to: next_month
      create_outages_from_pingdom pingdom_outages.states
      Pingdom::SummaryAverage.params={}
      average=Pingdom::SummaryAverage.find vpc.id, from: starting_at, to: next_month, includeuptime: true
      create_averages_from_pingdom average
      starting_at= next_month
    end
  end

  def outage_uptime
    outages.up(from,to).all.sum { |x| x.interval }
  end

  def outage_downtime
    outages.down(from,to).all.sum { |x| x.interval }
  end

  def outage_unknown
    outages.unknown(from,to).all.sum { |x| x.interval }
  end

  def average_uptime
    averages.all.sum { |x| x.totalup }
  end

  def average_downtime
    averages.all.sum { |x| x.totaldown }
  end

  def average_unknown
    averages.all.sum { |x| x.totalunknown }
  end

  def outage_adjusted_downtime
    outages.adjusted.all.sum { |x| x.interval }
  end

  def performance_uptime
    performances.sum(:uptime)
  end

  def performance_downtime
    performances.sum(:downtime)
  end

  def performance_unmonitored
    performances.sum(:unmonitored)
  end

  def performance_avgresponse
    performances.count>0 ? performances.total_avg/performances.count : 0
  end

  def average_avgresponse
    averages.count>0 ? averages.total_avg/averages.count : 0
  end

  def data_hash
    JSON.parse data, symbolize_names: true
  end


  private

  def validate_period
    validate_inclusion :period, PERIODS
  end

  def validate_resolution
    validate_inclusion :resolution, RESOLUTIONS
  end

end
