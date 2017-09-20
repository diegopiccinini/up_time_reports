class GlobalSetting < ApplicationRecord
  def self.get name
    s=self.find_by name: name
    s ? JSON.parse(s.data,symbolize_names: true) : false
  end
end
