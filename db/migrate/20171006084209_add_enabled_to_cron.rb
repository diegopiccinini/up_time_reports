class AddEnabledToCron < ActiveRecord::Migration[5.1]
  def change
    add_column :crons, :enabled, :boolean, default: true
  end
end
