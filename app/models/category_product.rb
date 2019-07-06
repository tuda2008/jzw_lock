# == Schema Information
#
# Table name: category_products
#
#  id          :bigint           not null, primary key
#  category_id :integer          not null
#  product_id  :integer          not null
#

class CategoryProduct < ApplicationRecord
  belongs_to :category
  belongs_to :product
end
