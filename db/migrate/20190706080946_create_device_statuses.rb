class CreateDeviceStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :device_statuses do |t|
	    t.string "name", limit: 50, default: "未绑定", null: false
	    t.integer "category_id", null: false
	    t.boolean "enable", default: true

	    t.index ["category_id", "enable"], name: "index_device_statuses_on_category_id_and_enable"
	    t.index ["category_id"], name: "index_device_statuses_on_category_id"
	    t.index ["enable"], name: "index_device_statuses_on_enable"
	    t.index ["name", "category_id", "enable"], name: "device_statuses_name_cate_enable", unique: true
	    t.index ["name"], name: "index_device_statuses_on_name"
    end
  end
end