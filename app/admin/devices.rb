ActiveAdmin.register Device do
  menu priority: 7, label: proc{ I18n.t("activerecord.models.device") }

  actions :index, :show

  filter :device_status  
  filter :alias
  filter :imei
  filter :created_at

  index do
    selectable_column
      id_column
      column :device_uuid
      column :device_status
      column :alias
      column :imei
      column :super_admin do |device|
      	device.super_admin.nil? ? "" : device.super_admin.name
      end
      column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :device_uuid
      row :device_status
      row :alias
      row :imei
      row :super_admin do |device|
        device.super_admin.nil? ? "" : device.super_admin.name
      end
      row :admin_user do |device|
        device.admin_users.map(&:name).join(',')
      end
      row :users do |device|
        device.users.map(&:name).join(',')
      end
      row :invitors do |device|
      	device.invitors.map(&:name).join(',')
      end
      row :created_at
    end
  end

end