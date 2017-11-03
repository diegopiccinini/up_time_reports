ActiveAdmin.register GlobalSetting do

  permit_params :name, :data

  form do |f|
    f.inputs do
      f.input :name
      f.input :data, as: :text, input_html: { class: 'jsoneditor-target' }
    end
    f.actions
  end
end
