class CreateAppVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :app_versions do |t|
	    t.integer "code", default: 1, null: false
	    t.string "name", null: false
	    t.integer "mobile_system", default: 3, null: false
	    t.text "content", null: false
	    t.datetime "created_at"

	    t.index ["code", "mobile_system"], name: "index_app_versions_on_code_and_mobile_system", unique: true
	    t.index ["code"], name: "index_app_versions_on_code"
	    t.index ["mobile_system"], name: "index_app_versions_on_mobile_system"
    end
  end
end