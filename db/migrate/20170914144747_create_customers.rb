class CreateCustomers < ActiveRecord::Migration[5.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :customers, :deleted_at
  end
end
