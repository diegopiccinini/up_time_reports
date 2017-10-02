class CreateAverages < ActiveRecord::Migration[5.1]
  def change
    create_table :averages do |t|
      t.belongs_to :report, foreign_key: true
      t.column :from,'timestamp with time zone'
      t.column :to,'timestamp with time zone'
      t.integer :avgresponse
      t.integer :totalup
      t.integer :totaldown
      t.integer :totalunknown

      t.timestamps
    end
  end
end
