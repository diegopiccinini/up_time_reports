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
  scope :outages_saved, -> { where( status: 'outages saved' ) }
  scope :vpc_reports_built, -> { where( status: 'vpc reports built' ) }
  scope :json_ready, -> { where( status: 'JSON ready') }
  scope :built, -> { where( status: ['JSON ready']) }

  def self.start date: , period: 'day', resolution: 'hour'

    date = GlobalSetting.date_in_default_timezone date if period!= 'month'

    History.write "** Starting #{period} reports on #{date} with resolution #{resolution}",2,2

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
      date.next_week - 1.day
    when 'month'
      if resolution=='week'
        to = date.next_month.at_end_of_month
        to-=1 until to.wday==0
        GlobalSetting.date_in_default_timezone to
      else
        date.next_month - 1.day
      end
    when 'year'
      if date.year == Date.today.year
        Date.today.in_time_zone(GlobalSetting.timezone).prev_month.at_end_of_month
      else
        date.next_year
      end
    end
  end

  def save_performances
    History.write "** Saving performances #{period} reports on #{start_date} with resolution #{resolution}",2,2
    step filter_scope: :started, update_method: :update_performances, status: 'performances saved'
  end

  def save_outages
    History.write "** Saving outages #{period} reports on #{start_date} with resolution #{resolution}",2,2
    step filter_scope: :performances_saved, update_method: :update_outages, status: 'outages saved'
  end

  def vpc_reports_build
    History.write "** Building VPC #{period} reports on #{start_date} with resolution #{resolution}",2,2
    reports.outages_saved.each do |r|
      r.destroy if r.outages.count == 0
    end
    step filter_scope: :outages_saved, update_method: :build, status: 'vpc reports built'
  end

  def save_year_outages
    History.write "** Saving outages #{period} reports on #{start_date} with resolution #{resolution}",2,2
    step filter_scope: :started, update_method: :update_year_outages, status: 'outages saved'
  end

  def step filter_scope:,  update_method: , status:

    reports.send(filter_scope).each do |report|
      begin
        History.write "\t#{update_method} on #{report.vpc.name}"
        report.send(update_method)
        report.status = status unless update_method==:build
      rescue => e
        message ="\n#{update_method} error on #{report.vpc.name}"
        message<< "\nError: #{e.message}"
        message<< "\n\nTrace: #{e.backtrace.join("\n")}"
        History.write message, level: 'error'
        report.status = status + ' error'
      end
      report.save
    end

    update( status: status )

  end

  def builder
    GlobalReportBuilder.new self
  end

  def build
    History.write "** Building Global #{period} report on #{start_date} with resolution #{resolution}",2,2
    builder.build
  end

  def data_hash
    JSON.parse data, symbolize_names: true
  end

  def name
    "#{period.capitalize} Report by #{resolution.capitalize} Resolution, on #{start_date.to_s}"
  end

  def built_data data_type, header_name, field=:formatted
    data_hash[data_type][builder.index header_name ][field]
  end

  def start_time
    start_date
  end

  private

  def validate_period
    validate_inclusion :period, PERIODS
  end

  def validate_resolution
    validate_inclusion :resolution, RESOLUTIONS
  end
end
