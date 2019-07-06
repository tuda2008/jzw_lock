class CreateMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :messages do |t|
      t.integer "user_id", null: false
      t.integer "device_id", null: false
      t.string "oper_cmd", limit: 20, null: false
      t.string "oper_username", limit: 20
      t.string "device_type", default: "lock", null: false
      t.string "content", limit: 60, default: ""
      t.string "avatar_path"
      t.string "gif_path"
      t.text "ori_picture_paths"
      t.integer "lock_num"
      t.integer "lock_type"
      t.boolean "is_deleted", default: false, null: false
      t.datetime "created_at", null: false
    
      t.index ["content"], name: "index_messages_on_content"
      t.index ["created_at"], name: "index_messages_on_created_at"
      t.index ["device_type"], name: "index_messages_on_device_type"
      t.index ["is_deleted", "created_at"], name: "index_messages_on_is_deleted_and_created_at"
      t.index ["is_deleted"], name: "index_messages_on_is_deleted"
      t.index ["oper_cmd"], name: "index_messages_on_oper_cmd"
      t.index ["oper_username"], name: "index_messages_on_oper_username"
      t.index ["user_id", "content", "is_deleted", "created_at"], name: "messages_user_content_visible_created"
      t.index ["user_id", "device_id", "content", "is_deleted", "created_at"], name: "messages_user_device_content_visible_created"
      t.index ["user_id", "device_id", "is_deleted", "created_at"], name: "messages_user_device_created_at"
      t.index ["user_id", "device_id", "is_deleted"], name: "index_messages_on_user_id_and_device_id_and_is_deleted"
      t.index ["user_id", "is_deleted", "created_at"], name: "index_messages_on_user_id_and_is_deleted_and_created_at"
      t.index ["user_id", "is_deleted"], name: "index_messages_on_user_id_and_is_deleted"
    end
  end
end