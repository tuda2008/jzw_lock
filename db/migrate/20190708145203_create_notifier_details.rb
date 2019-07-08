class CreateNotifierDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :notifier_details do |t|
    	t.integer  "sys_notifier_id",  null: false
	    t.string   "mobile",           default: ""
	    t.string   "content",          default: ""
      t.datetime "created_at",       null: false

      t.index ["sys_notifier_id"], name: "index_notifier_details_on_sys_notifier_id"
    end
  end
end