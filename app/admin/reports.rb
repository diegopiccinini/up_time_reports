ActiveAdmin.register Report do
  permit_params :status
  form title: 'Report edit' do |f|
    inputs 'Details' do
      input :status
    end
    actions
  end

  index do
    selectable_column
    column :vpc
    column :status
    column :global_report
    column :status
    actions
  end


  show do
    if report.status =='JSON ready'
      render 'data', { report: report.data_hash }
    else
      render 'not_ready'
    end
  end

end
