ActiveAdmin.register DeviceStatus do
  permit_params  :name, :category_id, :enable

  scope("全部A") { |status| status.all }
  scope("已启用Y") { |status| status.enable }
  scope("未启用N") { |status| status.disable }

  show do 
    attributes_table do
      row :id
      row :name
      row :category_id do |status|
        status.category.title
      end
      row :enable
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs do
      f.input :name 
      f.input :category_id, :as => :select, :collection => Category.visible.pluck(:title, :id), prompt: "请选择"
      f.input :enable
    end
    f.actions
  end

end