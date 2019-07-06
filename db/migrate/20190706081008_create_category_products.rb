class CreateCategoryProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :category_products do |t|
			t.integer "category_id", null: false
	    t.integer "product_id", null: false

	    t.index ["category_id", "product_id"], name: "index_category_products_on_category_id_and_product_id", unique: true
	    t.index ["category_id"], name: "index_category_products_on_category_id"
	    t.index ["product_id"], name: "index_category_products_on_product_id"
    end
  end
end