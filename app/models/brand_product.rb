# == Schema Information
#
# Table name: brand_products
#
#  id         :bigint           not null, primary key
#  brand_id   :integer          not null
#  product_id :integer          not null
#

class BrandProduct < ApplicationRecord
  belongs_to :brand
  belongs_to :product
end
