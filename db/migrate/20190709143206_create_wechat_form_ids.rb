class CreateWechatFormIds < ActiveRecord::Migration[5.2]
  def change
    create_table :wechat_form_ids do |t|
      t.integer  "user_id",      null: false
      t.text     "form_ids",     limit: 1000
      
      t.index ["user_id"], name: "index_wechat_form_ids_on_user_id"
    end
  end
end