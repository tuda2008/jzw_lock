class AddColumnOpenNeedWarnToDeviceUsers < ActiveRecord::Migration[5.2]
  def change
	  add_column :device_users, :open_need_warn, :boolean, default: false

  	add_index :device_users, [:device_id, :device_type, :open_need_warn], name: "index_device_users_on_device_type_open_warn"
  end
end