class CreateBrandProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :brand_products do |t|
	    t.integer "brand_id", null: false
	    t.integer "product_id", null: false

			t.index ["brand_id"], name: "index_brand_products_on_brand_id"
	    t.index ["product_id"], name: "index_brand_products_on_product_id"
	    t.index ["brand_id", "product_id"], name: "index_brand_products_on_brand_id_and_product_id", unique: true
	  end
  end
end