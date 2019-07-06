class CreateUserInvitors < ActiveRecord::Migration[5.2]
  def change
    create_table :user_invitors do |t|
			t.integer "invitation_id", null: false
	    t.integer "user_id", null: false
	    t.datetime "created_at"

      t.index ["invitation_id"], name: "index_user_invitors_on_invitation_id"
      t.index ["user_id", "invitation_id"], name: "index_user_invitors_on_user_id_and_invitation_id", unique: true
      t.index ["user_id"], name: "index_user_invitors_on_user_id"
    end
  end
end