ActiveAdmin.register GlobalReport do
  permit_params :status
  form title: 'Global Report edit' do |f|
    inputs 'Details' do
      input :status
    end
    actions
  end
  index do
    selectable_column
    column :name
    column :period
    column :resolution
    column :start_date
    column :status
    actions
  end
  show do
    if global_report.status =='JSON ready'
      render 'data', { report: global_report.data_hash }
    else
      render 'not_ready'
    end
  end
end
