class AddCronToHistory < ActiveRecord::Migration[5.1]
  def change
    add_reference :histories, :cron, index: true
  end
end
