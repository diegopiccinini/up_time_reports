class Performance < ApplicationRecord
  belongs_to :report
  scope :total_avg, -> { sum(:avgresponse) }

  def outage_incidents
    report.outages.where(timefrom: starttime..endtime, status: 'down')
  end

  def incidents
    outage_incidents.count
  end

  def adjusted_incidents
    outage_incidents.count do |outage|
      outage.interval > adjust_interval
    end
  end

  def endtime
    starttime + 1.send(report.resolution)
  end

  private

  def adjust_interval
    @adjust_interval||=GlobalSetting.get('adjust_interval')[:value]
    @adjust_interval
  end

end
