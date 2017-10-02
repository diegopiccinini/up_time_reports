class Average < ApplicationRecord
  belongs_to :report
  scope :by_period, -> (from,to) { where("averages.from >= ? and averages.to<= ?",from,to) }
  scope :total_avg, -> { sum(:avgresponse) }
end
