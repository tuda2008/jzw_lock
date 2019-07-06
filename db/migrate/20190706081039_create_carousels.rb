class CreateCarousels < ActiveRecord::Migration[5.2]
  def change
    create_table :carousels do |t|
	    t.string "tag", null: false
	    t.string "url"
	    t.string "images"
	    t.boolean "visible", default: false

	    t.index ["tag"], name: "index_carousels_on_tag", unique: true
	    t.index ["url"], name: "index_carousels_on_url"
	    t.index ["visible"], name: "index_carousels_on_visible"
    end
  end
end