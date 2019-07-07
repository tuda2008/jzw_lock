class CreateAuthCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :auth_codes do |t|
      t.string   "code",       limit: 255
	    t.string   "mobile",     limit: 255
	    t.integer  "auth_type",  limit: 4
	    t.boolean  "verified",   default: false
      t.timestamps

 			t.index ["code"], name: "index_auth_codes_on_code"
  		t.index ["mobile"], name: "index_auth_codes_on_mobile"
  		t.index ["code", "mobile"], name: "index_auth_codes_on_code_mobile"
  		t.index ["auth_type", "code", "mobile"], name: "index_auth_codes_on_type_code_mobile"
    end
  end
end