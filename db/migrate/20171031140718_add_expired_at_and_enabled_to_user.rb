class AddExpiredAtAndEnabledToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :expired_at, :datetime
    add_column :users, :enabled, :boolean, default: true
  end
end
