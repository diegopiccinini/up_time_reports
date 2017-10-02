class GlobalSetting < ApplicationRecord

  @@adjust_interval= nil
  @@timezone= nil

  def self.get name
    s=self.find_by name: name
    s ? JSON.parse(s.data,symbolize_names: true) : false
  end

  def self.set name, data_hash
    s=self.find_or_create_by name: name
    s.data= data_hash.to_json
    s.save
  end

  def self.adjust_interval
    @@adjust_interval||=GlobalSetting.get('adjust_interval')[:value]
  end

  def self.default_timezone
    @@timezone||=GlobalSetting.get('default_timezone')[:value]
  end

  def self.date_in_default_timezone date
    Date.parse( date.strftime("%d/%m/%Y") ).in_time_zone(self.default_timezone)
  end
end
