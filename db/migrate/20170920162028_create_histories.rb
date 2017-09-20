class CreateHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :histories do |t|
      t.string :text
      t.string :level , limit: 5, default: 'info'

      t.timestamps
    end
  end
end
