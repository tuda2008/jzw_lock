# == Schema Information
#
# Table name: categories
#
#  id      :bigint(8)        not null, primary key
#  title   :string(255)      not null
#  intro   :string(255)      default("")
#  images  :string(255)
#  visible :boolean          default(FALSE)
#

class Category < ApplicationRecord
  mount_uploaders :images, PhotoUploader
  serialize :images, Array

  has_many :brand_categories, :dependent => :destroy
  has_many :brands, :through => :brand_categories
  accepts_nested_attributes_for :brands, :allow_destroy => true

  has_many :category_products, :dependent => :destroy
  has_many :products, :through => :category_products
  accepts_nested_attributes_for :products, :allow_destroy => true

  has_many :device_uuids

  validates :title, presence: true, uniqueness: { case_sensitive: false }, length: { in: 2..60 }
  validates :intro, length: { allow_blank: true, maximum: 160 }

  scope :visible, -> { where(visible: true) }
  scope :invisible, -> { where(visible: false) }
end