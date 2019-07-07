class CreateDeviceUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :device_users do |t|
	    t.integer "device_id", null: false
	    t.integer "user_id"
	    t.integer "device_type", null: false
	    t.integer "device_num", null: false
	    t.string "username", limit: 40, null: false
			t.timestamps

	    t.index ["device_id", "device_type"], name: "index_device_users_on_device_id_and_device_type"
	    t.index ["device_id"], name: "index_device_users_on_device_id"
	    t.index ["device_type"], name: "index_device_users_on_device_type"
	    t.index ["user_id"], name: "index_device_users_on_user_id"
	    t.index ["device_id", "user_id"], name: "index_device_users_on_device_user_id"
    end
  end
end