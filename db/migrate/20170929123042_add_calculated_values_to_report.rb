class AddCalculatedValuesToReport < ActiveRecord::Migration[5.1]
  def change
    add_column :reports, :uptime, :integer
    add_column :reports, :downtime, :integer
    add_column :reports, :unknown, :integer
    add_column :reports, :adjusted_downtime, :integer
    add_column :reports, :avg_response, :integer
  end
end
