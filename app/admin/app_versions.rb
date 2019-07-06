ActiveAdmin.register AppVersion do
  menu priority: 11, label: proc{ I18n.t("activerecord.models.app_version") }

  permit_params :code, :name, :mobile_system, :content

  filter :code
  filter :name
  filter :mobile_system, as: :select, collection: AppVersion::MOBILESYSTEM_COLLECTION
  filter :content

  scope("全部A") { |version| version.all }
  scope("IOS") { |version| version.ios }
  scope("Android") { |version| version.android }
  scope("微信小程序W") { |version| version.wechat }
  scope("支付宝小程序Z") { |version| version.alipay }

  index do
    selectable_column
      id_column
      column :code
      column :name
      column :mobile_system  do |version|
        AppVersion::MOBILESYSTEM_HASH[version.mobile_system]
      end
      column :content do |version|
      	truncate(version.content, :length => 10)
      end
      column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :code
      row :name
      row :mobile_system do |version|
        AppVersion::MOBILESYSTEM_HASH[version.mobile_system]
      end
      row :content
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs do
      f.input :code
      f.input :name, :as => :string
      f.input :mobile_system, :as => :select, :collection => AppVersion::MOBILESYSTEM_COLLECTION, prompt: "请选择"
      f.input :content, :as => :string
    end
    f.actions
  end

end