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
      outage.interval / 60
    end
  end

  def endtime
    starttime + 1.send(report.resolution)
  end

  def row
    [
      unit_step,
      incidents,
      downtime_in_minutes,
      unmonitored_in_minutes,
      uptime_percent ,
      real_uptime_percent,
      adjusted_incidents,
      adjusted_downtime,
      adjusted_uptime,
      avgresponse
    ]
  end

  private

  def unit_step
    case report.resolution
    when 'week'
      starttime.localtime.to_date.to_s
    else
      starttime.localtime.send(report.resolution)
    end
  end

  def unmonitored_in_minutes
    unmonitored / 60
  end

  def downtime_in_minutes
    downtime / 60
  end

  def uptime_percent
    percent(downtime_in_minutes.to_f * 60.0)
  end

  def real_uptime_percent
    percent downtime.to_f
  end

  def adjusted_uptime
    percent( adjusted_downtime.to_f * 60.0)
  end

  def adjust_interval
    GlobalSetting.adjust_interval
  end

  def percent n
    n = (1.send(report.resolution).to_f - n.to_f) * 100.0 / 1.send(report.resolution).to_f
    format("%.3f", n )
  end

end
