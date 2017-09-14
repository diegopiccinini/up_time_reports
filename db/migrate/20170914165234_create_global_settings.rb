class CreateGlobalSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :global_settings do |t|
      t.string :name, null: false
      t.json :data

      t.timestamps
    end
    add_index :global_settings, :name, unique: true
  end
end
