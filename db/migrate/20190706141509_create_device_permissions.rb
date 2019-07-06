class CreateDevicePermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :device_permissions do |t|
    	t.integer "device_id", null: false
    	t.integer "ownership", null: false
	    t.integer "permission_id", null: false

	    t.index ["device_id"], name: "index_device_permissions_on_device"
	    t.index ["device_id", "ownership"], name: "index_device_permissions_on_device_ownership"
	    t.index ["device_id", "permission_id"], name: "index_device_permissions_on_device_permission"
    end
  end
end