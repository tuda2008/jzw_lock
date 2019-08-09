class CreateBleSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :ble_settings do |t|
      t.integer  "user_id",  null: false
      t.integer  "device_id",  null: false
      t.integer  "ble_type",  null: false
      t.string   "cycle"
      t.string   "cycle_start_at"
      t.string   "cycle_end_at"
      t.datetime "start_at"
      t.datetime "end_at"

      t.timestamps

      t.index ["user_id", "device_id"], name: "index_ble_settings_on_user_device"
      t.index ["user_id", "device_id", "ble_type"], name: "index_ble_settings_on_user_device_type"
    end
  end
end