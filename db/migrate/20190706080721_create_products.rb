class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
	    t.string "title", null: false
	    t.string "intro", default: ""
	    t.string "images"
	    t.boolean "visible", default: false

      t.timestamps

      t.index ["intro"], name: "index_products_on_intro"
      t.index ["title", "visible"], name: "index_products_on_title_and_visible", unique: true
      t.index ["title"], name: "index_products_on_title", unique: true
      t.index ["visible"], name: "index_products_on_visible"
    end
  end
end