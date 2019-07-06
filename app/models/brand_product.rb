# == Schema Information
#
# Table name: brand_products
#
#  id          :bigint(8)        not null, primary key
#  brand_id    :integer          not null
#  product_id  :integer          not null
#

class BrandProduct < ApplicationRecord
  belongs_to :brand
  belongs_to :product
end