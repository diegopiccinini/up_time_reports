class Report < ApplicationRecord

  acts_as_paranoid

  belongs_to :vpc
  belongs_to :global_report

  validates :status, presence: true

  has_many :performances, :dependent => :delete_all
  has_many :outages, :dependent => :delete_all
  has_many :averages, :dependent => :delete_all

  scope :by_period, -> (period='day') { includes(:global_report).where( period: period ) }

  scope :started, -> { where( status: 'start') }
  scope :performances_saved, -> { where( status: 'performances saved' ) }
  scope :performances_saved_total, -> { where( "status LIKE ?", 'performances saved%' ) }
  scope :outages_saved, -> { where( status: 'outages saved' ) }
  scope :outages_saved_total, -> { where( "status LIKE ?", 'outages saved%' ) }
  scope :json_ready, -> { where( status: 'JSON ready') }


  def self.server_time
    Pingdom::ServerTime.time
  end

  def self.start global_report

    Vpc.created_before(global_report.from).all.each do |vpc|
      self.create vpc: vpc, global_report: global_report ,status: 'start'
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

  def incidents
    outages.where(status: 'down').count
  end

  def adjusted_incidents
    outages.adjusted.count
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

  def start_date
    global_report.start_date
  end

  def period
    global_report.period
  end

  def resolution
    global_report.resolution
  end

  def from
    global_report.from
  end

  def to
    global_report.to
  end

end
