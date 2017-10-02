class CreateReports < ActiveRecord::Migration[5.1]
  def change
    create_table :reports do |t|
      t.string :resolution
      t.string :period
      t.date :start_date
      t.string :status
      t.column :from,'timestamp with time zone'
      t.column :to,'timestamp with time zone'
      t.json :data
      t.belongs_to :vpc, foreign_key: true

      t.column :deleted_at,'timestamp with time zone'
      t.timestamps
    end
    add_index :reports, :start_date
    add_index :reports, :deleted_at
  end
end
