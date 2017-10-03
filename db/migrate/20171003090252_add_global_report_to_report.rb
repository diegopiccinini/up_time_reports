class AddGlobalReportToReport < ActiveRecord::Migration[5.1]
  def change
    add_reference :reports, :global_report, foreign_key: true
    remove_column :reports, :resolution
    remove_column :reports, :period
    remove_column :reports, :start_date
    remove_column :reports, :from
    remove_column :reports, :to

  end
end
