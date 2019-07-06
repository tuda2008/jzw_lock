ActiveAdmin.register Message do
  menu priority: 6, label: proc{ I18n.t("activerecord.models.message") }
  actions :index, :show

  filter :user
  filter :device
  filter :is_deleted
  filter :created_at

  scope("全部A") { |message| message.all }
  scope("可见消息Y") { |message| message.visible }
  scope("不可见消息N") { |message| message.invisible }

  index do
    selectable_column
    id_column
    column :user
    column :device
    column :oper_cmd do |msg|
      Message::CMD_NAMES[msg.oper_cmd]
    end
    column :lock_num do |msg|
      msg.lock_number
    end
    column :content
    column :is_deleted
    column :created_at
    actions
  end

  show do 
    attributes_table do
      row :id
      row :user
      row :device
      row :oper_cmd do |msg|
        Message::CMD_NAMES[msg.oper_cmd]
      end
      row :lock_num do |msg|
        msg.lock_number
      end
      row :content
      row :is_deleted
      row :created_at
    end
  end
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

end