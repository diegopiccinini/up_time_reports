class CreateOutages < ActiveRecord::Migration[5.1]
  def change
    create_table :outages do |t|
      t.datetime :timefrom
      t.datetime :timeto
      t.string :status, limit: 10
      t.belongs_to :report, foreign_key: true

      t.timestamps
    end
  end
end
