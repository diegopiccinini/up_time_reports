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
    report.outages.where(timefrom: starttime..endtime).adjusted.count
  end

  def adjusted_downtime
    report.outages.where(timefrom: starttime..endtime).adjusted.sum do |outage|
      outage.interval
    end
  end

  def endtime
    starttime + 1.send(report.resolution)
  end

  def unit_step
    case report.resolution
    when 'week'
      starttime.in_time_zone(GlobalSetting.timezone).to_date.to_s
    else
      starttime.in_time_zone(GlobalSetting.timezone).send(report.resolution)
    end
  end

end
