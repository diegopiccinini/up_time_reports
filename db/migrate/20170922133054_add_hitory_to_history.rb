class AddHitoryToHistory < ActiveRecord::Migration[5.1]
  def change
    add_column :histories, :history_id, :integer, index: true
  end
end
