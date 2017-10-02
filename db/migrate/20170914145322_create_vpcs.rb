class CreateVpcs < ActiveRecord::Migration[5.1]
  def change
    create_table :vpcs do |t|
      t.string :hostname
      t.column :lasterrortime ,'timestamp with time zone'
      t.integer :lastresponsetime
      t.column :lasttesttime,'timestamp with time zone'
      t.string :name
      t.integer :resolution
      t.string :status
      t.json :data
      t.belongs_to :customer, foreign_key: true
      t.string :check_type
      t.string :timezone, default: 'London'
      t.column :deleted_at,'timestamp with time zone'
      t.timestamps
    end
    add_index :vpcs, :deleted_at
  end
end
