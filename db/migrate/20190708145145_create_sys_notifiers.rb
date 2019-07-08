class CreateSysNotifiers < ActiveRecord::Migration[5.2]
  def change
    create_table :sys_notifiers do |t|
	    t.integer  "device_id",      null: false
	    t.integer  "author_id",      null: false
	    t.integer  "notifier_type",  null: false, limit: 4, default: 1
	    t.boolean  "disabled",       default: false
      t.timestamps

      t.index ["device_id", "notifier_type", "disabled"], name: "index_sys_notifiers_on_device_notifier_disabled"
    end
  end
end