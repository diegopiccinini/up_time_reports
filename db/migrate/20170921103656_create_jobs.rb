class CreateJobs < ActiveRecord::Migration[5.1]
  def change
    create_table :jobs do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :jobs, :name, unique: true
  end
end
