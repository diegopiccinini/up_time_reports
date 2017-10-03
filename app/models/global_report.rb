class GlobalReport < ApplicationRecord

  acts_as_paranoid

  has_many :reports, :dependent => :delete_all

  validates :status,:start_date, presence: true
  validate :validate_period
  validate :validate_resolution

  PERIODS = %w(day week month year)
  RESOLUTIONS =  %w(hour day week month)

  scope :by_period, -> (period='day') { where( period: period ) }
  scope :by_date, -> (date) { where( start_date: date ) }
  scope :by_date_and_period, -> (date,period) { where( start_date: date, period: period ) }
  scope :daily, -> (date) { by_period.by_date(date) }

  scope :started, -> (date, period='day') { by_date_and_period(date,period).where( status: 'start') }
  scope :outages_saved, -> (date, period='day') { by_date_and_period(date,period).where( status: 'outages saved' ) }
  scope :json_ready, -> { where( status: 'JSON ready') }

  def self.start date: , period: 'day', resolution: 'hour'

    date = GlobalSetting.date_in_default_timezone date

    History.write "** Starting #{period} reports on #{date}",2,2

    where( start_date: date, period: period, resolution: resolution ).each do |gr|
      gr.reports.destroy_all
      gr.destroy
    end

    to = get_to date, period, resolution

    global_report=create start_date: date, status: 'start', from: date.to_time, to: to.to_time, period: period, resolution: resolution

    Report.start global_report

    global_report

  end

  def self.get_to date, period, resolution
    case period
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
  end

  def self.save_performances
    History.write "** Saving performances",2,2
    where(status: 'start').each do |global_report|
      step global_report: global_report, filter_scope: :started, update_method: :update_performances, status: 'performances saved'
    end
  end

  def self.save_outages
    History.write "** Saving outages",2,2
    where(status: 'performances saved').each do |global_report|
      step global_report: global_report, filter_scope: :performances_saved, update_method: :update_outages, status: 'outages saved'
    end
  end

  def self.save_year_outages
    History.write "** Saving outages",2,2
    where(status: 'performances saved', period: 'year' ).each do |global_report|
      step global_report: global_report, filter_scope: :started, update_method: :update_year_outages, status: 'outages saved'
    end
  end

  def self.step global_report:, filter_scope:,  update_method: , status:

    global_report.reports.send(filter_scope).each do |report|
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

    global_report.update( status: status )

  end

  private

  def validate_period
    validate_inclusion :period, PERIODS
  end

  def validate_resolution
    validate_inclusion :resolution, RESOLUTIONS
  end
end
