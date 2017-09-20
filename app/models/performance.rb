class Performance < ApplicationRecord
  belongs_to :report
  scope :total_avg, -> { sum(:avgresponse) }
end
