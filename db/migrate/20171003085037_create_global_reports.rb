class CreateGlobalReports < ActiveRecord::Migration[5.1]
  def change
    create_table :global_reports do |t|
      t.string :resolution, null: false
      t.string :period, null: false
      t.date :start_date, null: false
      t.string :status, null: false
      t.column :from,'timestamp with time zone', null: false
      t.column :to,'timestamp with time zone', null: false
      t.json :data
      t.column :deleted_at,'timestamp with time zone'
      t.timestamps
    end
    add_index :global_reports, [:start_date, :period, :resolution, :deleted_at] , unique: true, name: 'unique_global_report_index'
    add_index :global_reports, :deleted_at
  end
end
