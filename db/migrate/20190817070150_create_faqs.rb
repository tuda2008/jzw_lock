class CreateFaqs < ActiveRecord::Migration[5.2]
  def change
    create_table :faqs do |t|
	    t.string "title", null: false
	    t.text "content"
	    t.string "images"
	    t.boolean "visible", default: false

      t.timestamps

      t.index ["title"], name: "index_faqs_on_title"
	    t.index ["visible"], name: "index_faqs_on_visible"
    end
  end
end