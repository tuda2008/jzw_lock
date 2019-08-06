class CreateUserDevices < ActiveRecord::Migration[5.2]
  def change
    create_table :user_devices do |t|
      t.integer "author_id", null: false
	    t.integer "user_id", null: false
	    t.integer "device_id"
	    t.integer "ownership", default: 1, null: false
      t.integer "finger_count", default: 0
      t.integer "password_count", default: 0
      t.integer "card_count", default: 0
      t.integer "temp_pwd_count", default: 0
      t.boolean "has_ble_setting", default: false
	    t.boolean "visible", default: true

      t.index ["author_id"], name: "index_user_devices_on_author_id"
      t.index ["device_id"], name: "index_user_devices_on_device_id"
      t.index ["user_id", "device_id", "ownership"], name: "index_user_devices_on_user_id_and_device_id_and_ownership", unique: true
      t.index ["user_id", "device_id"], name: "index_user_devices_on_user_id_and_device_id"
      t.index ["user_id"], name: "index_user_devices_on_user_id"
      t.index ["visible"], name: "index_user_devices_on_visible"
    end
  end
end