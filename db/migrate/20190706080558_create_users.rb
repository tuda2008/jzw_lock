class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
	    t.integer "provider", default: 1, null: false
	    t.string "nickname"
	    t.string "mobile"
	    t.string "avatar_url"
	    t.string "open_id"
	    t.string "session_key"
	    t.string "country"
	    t.string "province"
	    t.string "city"
	    t.integer "gender", null: false
	    t.integer "invitor_id"

	    t.string "latitude", limit: 30, default: ""
	    t.string "longitude", limit: 30, default: ""
	    t.string "address", limit: 120, default: ""
	    t.date   "birthday"

	    t.timestamps

	    t.index ["address"], name: "index_users_on_address"
	    t.index ["city"], name: "index_users_on_city"
	    t.index ["gender"], name: "index_users_on_gender"
	    t.index ["invitor_id"], name: "index_users_on_invitor_id"
	    t.index ["latitude", "longitude"], name: "index_users_on_latitude_and_longitude"
	    t.index ["nickname"], name: "index_users_on_nickname"
	    t.index ["open_id"], name: "index_users_on_open_id"
	    t.index ["provider", "open_id"], name: "index_users_on_provider_and_open_id"
	    t.index ["provider"], name: "index_users_on_provider"
	    t.index ["province"], name: "index_users_on_province"
	    t.index ["session_key"], name: "index_users_on_session_key"
    end
  end
end