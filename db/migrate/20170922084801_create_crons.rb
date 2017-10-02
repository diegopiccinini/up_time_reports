class CreateCrons < ActiveRecord::Migration[5.1]
  def change
    create_table :crons do |t|
      t.string :name
      t.belongs_to :job, foreign_key: true
      t.integer :hour, limit: 2
      t.integer :day_of_week, limit: 1
      t.integer :day_of_month, limit: 2
      t.integer :month, limit: 2
      t.string :status, limit: 10, default: 'ok'
      t.column :last_execution ,'timestamp with time zone'
      t.column :next_execution ,'timestamp with time zone'
      t.string :message

      t.timestamps
    end
  end
end
