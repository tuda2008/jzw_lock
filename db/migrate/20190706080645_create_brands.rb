class CreateBrands < ActiveRecord::Migration[5.2]
  def change
    create_table :brands do |t|
	    t.string "name", limit: 120, null: false
	    t.string "abbr", limit: 60, default: ""
	    t.string "intro", default: ""
	    t.string "tel", default: ""
	    t.string "images"
	    t.boolean "visible", default: false

      t.timestamps

      t.index ["abbr"], name: "index_brands_on_abbr"
      t.index ["intro"], name: "index_brands_on_intro"
      t.index ["name", "visible"], name: "index_brands_on_name_and_visible", unique: true
      t.index ["name"], name: "index_brands_on_name", unique: true
      t.index ["tel"], name: "index_brands_on_tel"
      t.index ["visible"], name: "index_brands_on_visible"
    end
  end
end