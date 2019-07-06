class CreateInvitations < ActiveRecord::Migration[5.2]
  def change
    create_table :invitations do |t|
	    t.integer "user_id", null: false
	    t.integer "device_id", null: false
	    t.string "invitation_token", null: false
	    t.integer "invitation_limit", default: 5, null: false
	    t.datetime "invitation_expired_at"
	    t.datetime "invitation_accepted_at"
	    t.datetime "invitation_created_at"

	    t.index ["device_id"], name: "index_invitations_on_device_id"
	    t.index ["invitation_token"], name: "index_invitations_on_invitation_token", unique: true
	    t.index ["user_id", "device_id"], name: "index_invitations_on_user_id_and_device_id"
	    t.index ["user_id"], name: "index_invitations_on_user_id"
    end
  end
end