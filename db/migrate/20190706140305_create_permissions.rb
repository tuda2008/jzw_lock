class CreatePermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :permissions do |t|
	    t.integer "product_id", null: false
	    t.string "permission", null: false
	    t.boolean "visible", default: true

      t.index ["permission"], name: "index_permissions_on_permission"
	    t.index ["product_id"], name: "index_permissions_on_product_id"
	    t.index ["product_id", "visible"], name: "index_permissions_on_product_id_visible"
	    t.index ["visible"], name: "index_permissions_on_visible"
    end
  end
end