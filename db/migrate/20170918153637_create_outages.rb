class CreateOutages < ActiveRecord::Migration[5.1]
  def change
    create_table :outages do |t|
      t.string :status
      t.datetime :timefrom
      t.datetime :timeto
      t.belongs_to :vpc, foreign_key: true

      t.timestamps
    end
    add_index :outages, [:vpc_id, :timefrom], unique: true
  end
end
