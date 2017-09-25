class Cron < ApplicationRecord
  belongs_to :job
  has_many :histories

  validates :name, :hour, presence: true
  validates :status, inclusion: { in: %w(ok enqueue running error) }
  validates :hour, numericality: { only_integer: true, greater_than_or_equal: 0, less_than_or_equal: 23 }
  validate :month_validation
  validate :day_of_week_validation
  validate :day_of_month_validation

  before_save do |cron|
    cron.next_execution=cron.check_next_execution!
  end

  def in_range? start_time, end_time
    in_range= (start_time..end_time).include? (start_time.change(hour: 0) + hour.hours)
    in_range&= in_day_of_week?(start_time) if day_of_week
    in_range&= in_day_of_month?(start_time) if day_of_month
    in_range&= in_month?(start_time) if month
    in_range
  end

  def in_day_of_week? time
    day_of_week == time.wday
  end

  def in_day_of_month? time
    day_of_month == time.day
  end

  def in_month? time
    month == time.month
  end

  def month_validation
    unless month.nil?
      validate_inclusion :month, (1..12).to_a
    end
  end

  def day_of_week_validation
    unless day_of_week.nil?
      validate_inclusion :day_of_week, (0..6).to_a
    end
  end

  def day_of_month_validation
    unless day_of_month.nil?

      last_day= case month
                when nil
                  31
                when 2
                  28
                when [4,6,9,11]
                  30
                else
                  31
                end

      validate_inclusion :day_of_month, (1..last_day).to_a
    end
  end

  def run!
    history=job.run!(self)
    if history.is_a?(History)
      update status: 'running'
    else
      update status: 'enqueue'
    end
  end

  def finish!
    update(status: 'ok', last_execution: Time.now)
  end

  def check_next_execution!
    start_time = Date.today.to_time + (hour + 1).hours
    loop do
      end_time = start_time + 3599
      break if in_range?(start_time, end_time)
      start_time+=3600
    end
    start_time
  end

end
