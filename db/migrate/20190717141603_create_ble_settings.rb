class CreateBleSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :ble_settings do |t|
      t.integer  "user_id",  null: false
      t.integer  "device_id",  null: false
      t.string   "cycle"
      t.datetime "start_at", null: false
      t.datetime "end_at", null: false

      t.timestamps

      t.index ["user_id", "device_id"], name: "index_ble_settings_on_user_device"
      t.index ["user_id", "device_id", "cycle"], name: "index_ble_settings_on_user_device_cycle"
    end
  end
end