class SetPercentIntervalColorInGlobalSetting < ActiveRecord::Migration[5.1]
  def up
    GlobalSetting.set( 'percent_interval_colors', { min: 0.9995, max: 1.0 })
  end
  def down
    g=GlobalSetting.find_by name: 'percent_interval_colors'
    g.delete
  end
end
