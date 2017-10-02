class CreateCustomers < ActiveRecord::Migration[5.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.column :deleted_at,'timestamp with time zone'
      t.timestamps
    end
    add_index :customers, :deleted_at
  end
end
