# == Schema Information
#
# Table name: brand_categories
#
#  id          :bigint(8)        not null, primary key
#  brand_id    :integer          not null
#  category_id :integer          not null
#

class BrandCategory < ApplicationRecord
  belongs_to :brand
  belongs_to :category
end