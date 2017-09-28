class AddSourceAndOutToJob < ActiveRecord::Migration[5.1]
  def change
    add_column :jobs, :source, :text
    add_column :jobs, :out, :text
  end
end
