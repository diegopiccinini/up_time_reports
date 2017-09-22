class Cron < ApplicationRecord
  belongs_to :job

  validates :name, :hour, presence: true
  validates :status, inclusion: { in: %w(ok running error) }
  validates :hour, numericality: { only_integer: true, greater_than_or_equal: 0, less_than_or_equal: 23 }
  validate :month_validation
  validate :day_of_week_validation
  validate :day_of_month_validation

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
end
