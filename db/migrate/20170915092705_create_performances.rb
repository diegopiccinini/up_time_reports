class CreatePerformances < ActiveRecord::Migration[5.1]
  def change
    create_table :performances do |t|
      t.column :starttime,'timestamp with time zone'
      t.integer :avgresponse
      t.integer :uptime
      t.integer :downtime
      t.integer :unmonitored
      t.belongs_to :report, foreign_key: true

      t.timestamps
    end
  end
end
