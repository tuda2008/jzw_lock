class CreateDevices < ActiveRecord::Migration[5.2]
  def change
    create_table :devices do |t|
	    t.string "uuid", limit: 10
	    t.string "mac", limit: 60
	    t.string "token", null: false

	    t.integer "status_id", null: false
	    t.string "alias", limit: 50, default: "门锁", null: false

	    t.string "imei", limit: 60, default: ""
	    t.integer "open_num", default: 0
	    t.boolean "low_qoe", default: false
	    t.boolean "is_deleted", default: false, null: false

	    t.string "wifi_mac", limit: 30
	    t.bigint "port"

	    t.timestamps

	    t.index ["alias"], name: "index_devices_on_alias"
	    t.index ["imei"], name: "index_devices_on_imei"
	    t.index ["mac"], name: "index_devices_on_mac", unique: true
	    t.index ["low_qoe"], name: "index_devices_on_low_qoe"
	    t.index ["open_num"], name: "index_devices_on_open_num"
	    t.index ["port"], name: "index_devices_on_port"
	    t.index ["status_id"], name: "index_devices_on_status_id"
	    t.index ["token"], name: "index_devices_on_token"
	    t.index ["uuid"], name: "index_devices_on_uuid"
	    t.index ["wifi_mac"], name: "index_devices_on_wifi_mac"
    end
  end
end