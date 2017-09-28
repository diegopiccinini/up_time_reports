class Job < ApplicationRecord
  has_many :crons, dependent: :delete_all

  def run! cron: nil
    update out: nil
    update out: eval(source)
  end

end
