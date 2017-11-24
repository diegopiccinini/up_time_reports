ActiveAdmin.register Cron do
  permit_params :name, :status, :hour, :day_of_week, :day_of_month , :month, :enabled
end
