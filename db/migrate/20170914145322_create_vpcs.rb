class CreateVpcs < ActiveRecord::Migration[5.1]
  def change
    create_table :vpcs do |t|
      t.string :hostname
      t.datetime :lasterrortime
      t.integer :lastresponsetime
      t.datetime :lasttesttime
      t.string :name
      t.integer :resolution
      t.string :status
      t.json :data
      t.belongs_to :customer, foreign_key: true
      t.string :check_type
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :vpcs, :deleted_at
  end
end
