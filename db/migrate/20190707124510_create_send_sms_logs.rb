class CreateSendSmsLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :send_sms_logs do |t|
	    t.string   "mobile",            limit: 255
	    t.integer  "send_type",         limit: 4
	    t.integer  "sms_total",         limit: 4,   default: 0
	    t.datetime "first_sms_sent_at"
	  	t.timestamps
      
      t.index ["mobile", "send_type"], name: "index_sms_logs_on_mobile_type"
    end
  end
end