class AddStatusToHistory < ActiveRecord::Migration[5.1]
  def change
    add_column :histories, :status, :string, limit: 10, default: 'message'
  end
end
