class CreateBrandCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :brand_categories do |t|
	    t.integer "brand_id", null: false
	    t.integer "category_id", null: false

	    t.index ["brand_id"], name: "index_brand_categories_on_brand_id"
    	t.index ["category_id"], name: "index_brand_categories_on_category_id"
    	t.index ["brand_id", "category_id"], name: "index_brand_categories_on_brand_id_and_category_id", unique: true
    end
	end
end