ActiveAdmin.register Cron do
  permit_params :status, :hour, :day_of_week, :day_of_month , :month, :enabled
end
