class AddJobAndStatusToHistory < ActiveRecord::Migration[5.1]
  def change
    add_reference :histories, :job, foreign_key: true
    add_column :histories, :status, :string, limit: 10, default: 'message'
  end
end
